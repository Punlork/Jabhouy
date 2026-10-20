// Runs against a real in-memory database: what matters is the rows left
// behind, which a mocked DAO cannot show.
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jabhouy_core/jabhouy_core.dart';
import 'package:jabhouy_net/jabhouy_net.dart';
import 'package:jabhouy_shop/jabhouy_shop.dart';
import 'package:jabhouy_sync/jabhouy_sync.dart';
import 'package:mocktail/mocktail.dart';

class _MockConnectivity extends Mock implements ConnectivityService {}

class _Scope implements ShopScope {
  _Scope(this.shopId, {this.syncs = true, this.role = MemberRole.owner});

  @override
  final String shopId;
  @override
  final bool syncs;
  @override
  final MemberRole role;
  @override
  String get userId => 'u1';
}

const _drinks = 'cat-drinks';

PriceOption _option(String unit, int? price, {int? packQty}) => PriceOption(
  id: newId(),
  unit: unit,
  currency: Currency.khr,
  price: price,
  packQty: packQty,
);

void main() {
  late AppDatabase db;
  late SyncEngine engine;
  late _MockConnectivity connectivity;

  ItemRepository repo(String shopId, {bool syncs = true}) => ItemRepository(
    ItemDao(db),
    _Scope(shopId, syncs: syncs),
    engine,
    connectivity,
  );

  Future<List<OutboxEntry>> jobs() => db.select(db.outboxEntries).get();

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    engine = SyncEngine(database: db, transport: AdapterSyncTransport([]));
    connectivity = _MockConnectivity();
    when(() => connectivity.isOnline).thenAnswer((_) async => false);
  });

  tearDown(() => db.close());

  test('one form saves one item with two price options', () async {
    final shop = repo('s1');
    await shop.saveItem(
      Item(
        id: 'coke',
        name: 'Coca-Cola',
        categoryId: _drinks,
        prices: [_option('ដប', 3000), _option('កេះ', 60000, packQty: 24)],
      ),
    );

    final items = await shop.watchItems().first;
    expect(items.single.prices.map((p) => p.unit), ['ដប', 'កេះ']);
    expect(items.single.prices.last.packQty, 24);
    expect(items.single.prices.first.selling, const Money(3000, Currency.khr));
  });

  test('nicknames and a row barcode round-trip', () async {
    final shop = repo('s1');
    await shop.saveItem(
      Item(
        id: 'kulen',
        name: 'ទឹកអូគូលេនធំ',
        nicknames: const ['ទឹកធំ', 'Kulen'],
        prices: [
          PriceOption(
            id: newId(),
            unit: 'ដប',
            currency: Currency.khr,
            price: 3000,
            barcode: '8851234567890',
          ),
          _option('កេះ', null, packQty: 24),
        ],
      ),
    );

    final item = (await shop.watchItems().first).single;
    expect(item.nicknames, ['ទឹកធំ', 'Kulen']);
    expect(item.prices.map((p) => p.barcode), ['8851234567890', null]);
  });

  test('an empty price stays null and counts as missing', () async {
    final shop = repo('s1');
    await shop.saveItem(
      Item(id: 'rice', name: 'អង្ករ', prices: [_option('គីឡូ', null)]),
    );
    await shop.saveItem(
      Item(id: 'coke', name: 'Coca-Cola', prices: [_option('ដប', 3000)]),
    );

    final items = await shop.watchItems().first;
    expect(items.firstWhere((i) => i.id == 'rice').prices.single.price, isNull);
    expect(await shop.watchMissingPriceCount().first, 1);
    final missing = await shop.watchItems(missingOnly: true).first;
    expect(missing.map((i) => i.id), ['rice']);
  });

  test('an edit that drops a price option removes it', () async {
    final shop = repo('s1');
    final bottle = _option('ដប', 3000);
    await shop.saveItem(
      Item(id: 'coke', name: 'Coca-Cola', prices: [bottle, _option('កេះ', 1)]),
    );
    await shop.saveItem(Item(id: 'coke', name: 'Coca-Cola', prices: [bottle]));

    final items = await shop.watchItems().first;
    expect(items.single.prices.map((p) => p.unit), ['ដប']);
    expect(await db.select(db.itemPriceTable).get(), hasLength(1));
  });

  test('a search ranks in memory and finds nicknames', () async {
    final shop = repo('s1');
    await shop.saveItem(
      const Item(
        id: 'vital',
        name: 'Vital 1.5L',
        nicknames: ['ទឹកធំ'],
        prices: [],
      ),
    );
    await shop.saveItem(const Item(id: 'big', name: 'ទឹកធំ', prices: []));

    final found = await shop.watchItems(search: 'ទឹកធំ').first;
    expect([for (final i in found) i.id], ['big', 'vital']);
  });

  group('recently viewed', () {
    late DateTime now;
    ItemRepository ticking(String shopId) => ItemRepository(
      ItemDao(db),
      _Scope(shopId),
      engine,
      connectivity,
      clock: () => now = now.add(const Duration(minutes: 1)),
    );
    Future<List<String>> recent(ItemRepository shop) async => [
      for (final i in await shop.watchRecentItems().first) i.id,
    ];

    setUp(() => now = DateTime.utc(2026, 10, 19));

    test('keeps the 10 newest, newest first', () async {
      final shop = ticking('s1');
      for (var i = 1; i <= 12; i++) {
        await shop.saveItem(Item(id: 'i$i', name: 'i$i', prices: const []));
        await shop.recordView('i$i');
      }
      expect(await recent(shop), [for (var i = 12; i >= 3; i--) 'i$i']);
      expect(await db.select(db.recentItemTable).get(), hasLength(10));
    });

    test('re-opening moves an item to the front without a duplicate', () async {
      final shop = ticking('s1');
      for (final id in ['a', 'b', 'c']) {
        await shop.saveItem(Item(id: id, name: id, prices: const []));
        await shop.recordView(id);
      }
      await shop.recordView('a');
      expect(await recent(shop), ['a', 'c', 'b']);
    });

    test("another shop's recents are not shown, and nothing is queued",
        () async {
      final mine = ticking('s1');
      final theirs = ticking('s2');
      await theirs.saveItem(const Item(id: 'x', name: 'x', prices: []));
      await theirs.recordView('x');
      await db.delete(db.outboxEntries).go();
      await theirs.recordView('x');

      expect(await recent(mine), isEmpty);
      expect(await recent(theirs), ['x']);
      expect(await jobs(), isEmpty);
    });

    test('a deleted item drops out', () async {
      final shop = ticking('s1');
      await shop.saveItem(
        Item(id: 'a', name: 'a', prices: [_option('ដប', 3000)]),
      );
      await shop.recordView('a');
      expect((await shop.watchRecentItems().first).single.prices, hasLength(1));

      await shop.deleteItem('a');
      expect(await recent(shop), isEmpty);
    });
  });

  test(
    'a scanned barcode finds every live item using it in this shop',
    () async {
      final shop = repo('s1');
      PriceOption coded(String unit, String? code) => PriceOption(
        id: newId(),
        unit: unit,
        currency: Currency.khr,
        price: 3000,
        barcode: code,
      );
      await shop.saveItem(
        Item(
          id: 'water',
          name: 'ទឹក',
          prices: [coded('ដប', '885'), coded('កេះ', null)],
        ),
      );
      await shop.saveItem(
        Item(id: 'dup', name: 'ទឹក២', prices: [coded('ដប', '885')]),
      );
      await shop.saveItem(
        Item(id: 'gone', name: 'ចាស់', prices: [coded('ដប', '885')]),
      );
      await shop.deleteItem('gone');
      await repo('s2').saveItem(
        Item(id: 'other', name: 'ផ្សេង', prices: [coded('ដប', '885')]),
      );

      final found = await shop.itemsWithBarcode('885');
      expect([for (final i in found) i.id], ['water', 'dup']);
      expect(
        found.first.prices,
        hasLength(2),
        reason: 'every row, for the sheet',
      );
      expect(await shop.itemsWithBarcode('000'), isEmpty);
    },
  );

  test('delete leaves a tombstone and hides the item', () async {
    final shop = repo('s1');
    await shop.saveItem(
      Item(id: 'coke', name: 'Coca-Cola', prices: [_option('ដប', 3000)]),
    );
    await shop.deleteItem('coke');

    expect(await shop.watchItems().first, isEmpty);
    final row = await db.select(db.itemTable).getSingle();
    expect(row.deletedAt, isNotNull);
  });

  test("another shop's items never show", () async {
    await repo('s2')
        .saveItem(Item(id: 'other', name: 'Other', prices: [_option('ដប', 1)]));
    expect(await repo('s1').watchItems().first, isEmpty);
  });

  test('new units join the category, ordered by use', () async {
    final shop = repo('s1');
    await shop.saveCategory(
      const ItemCategory(
        id: _drinks,
        name: 'ភេសជ្ជៈ',
        units: [CategoryUnit(unit: 'កំប៉ុង')],
      ),
    );
    for (final id in ['a', 'b']) {
      await shop.saveItem(
        Item(id: id, name: id, categoryId: _drinks, prices: [_option('ដប', 1)]),
      );
    }
    await shop.saveItem(
      Item(
        id: 'c',
        name: 'c',
        categoryId: _drinks,
        prices: [_option('កេះ', 1)],
      ),
    );

    expect(await shop.unitsFor(_drinks), ['ដប', 'កេះ', 'កំប៉ុង']);
  });

  test('saving a category merges units and never removes one', () async {
    final shop = repo('s1');
    await shop.saveCategory(
      const ItemCategory(
        id: _drinks,
        name: 'ភេសជ្ជៈ',
        units: [
          CategoryUnit(unit: 'ដប'),
          CategoryUnit(unit: 'កេះ'),
        ],
      ),
    );
    await shop.saveCategory(
      const ItemCategory(
        id: _drinks,
        name: 'ភេសជ្ជៈ',
        units: [CategoryUnit(unit: 'កេះ', hidden: true)],
      ),
    );

    expect(await shop.unitsFor(_drinks), ['ដប']);
    final units = (await shop.watchCategories().first).single.units;
    expect(units, hasLength(2));
  });

  test(
    'reordering rewrites every sort order and queues each category',
    () async {
      final shop = repo('s1');
      for (final (i, id) in ['a', 'b', 'c'].indexed) {
        await shop.saveCategory(ItemCategory(id: id, name: id, sortOrder: i));
      }
      await db.delete(db.outboxEntries).go();

      await shop.reorderCategories(['c', 'a', 'b']);

      final ordered = await shop.watchCategories().first;
      expect([for (final c in ordered) c.id], ['c', 'a', 'b']);
      expect([for (final c in ordered) c.sortOrder], [0, 1, 2]);
      expect(await jobs(), hasLength(3));
    },
  );

  test('a viewer may not change categories', () async {
    final viewer = ItemRepository(
      ItemDao(db),
      _Scope('s1', role: MemberRole.viewer),
      engine,
      connectivity,
    );
    expect(
      await viewer.saveCategory(const ItemCategory(id: 'a', name: 'a')),
      isA<Err<ItemCategory>>(),
    );
    expect(await viewer.reorderCategories(['a']), isA<Err<void>>());
    expect(await viewer.watchCategories().first, isEmpty);
  });

  test('a barcode in use names its item, but not the one being edited',
      () async {
    final shop = repo('s1');
    await shop.saveItem(
      Item(
        id: 'coke',
        name: 'Coca-Cola',
        prices: [
          PriceOption(
            id: newId(),
            unit: 'ដប',
            currency: Currency.khr,
            barcode: '885',
          ),
        ],
      ),
    );
    await repo('s2').saveItem(
      Item(
        id: 'other',
        name: 'Other shop',
        prices: [
          PriceOption(
            id: newId(),
            unit: 'ដប',
            currency: Currency.khr,
            barcode: '999',
          ),
        ],
      ),
    );

    expect(
      await shop.barcodeOwners(['885', '999'], exceptItemId: 'new'),
      {'885': 'Coca-Cola'},
    );
    expect(await shop.barcodeOwners(['885'], exceptItemId: 'coke'), isEmpty);
  });

  test('a same-named item is found, ignoring case and spaces', () async {
    final shop = repo('s1');
    await shop.saveItem(
      Item(id: 'coke', name: 'Coca-Cola', prices: [_option('ដប', 3000)]),
    );

    expect(await shop.itemNamed(' coca-cola ', exceptItemId: 'new'), 'coke');
    expect(await shop.itemNamed('Coca-Cola', exceptItemId: 'coke'), isNull);
  });

  test('the last used category is the newest saved item with one', () async {
    var now = DateTime.utc(2026, 10, 19);
    final shop = ItemRepository(
      ItemDao(db),
      _Scope('s1'),
      engine,
      connectivity,
      clock: () => now = now.add(const Duration(minutes: 1)),
    );
    expect(await shop.lastUsedCategoryId(), isNull);
    await shop.saveItem(
      Item(id: 'a', name: 'a', categoryId: 'rice', prices: [_option('ដប', 1)]),
    );
    await shop.saveItem(
      Item(id: 'b', name: 'b', categoryId: _drinks, prices: [_option('ដប', 1)]),
    );
    await shop.saveItem(Item(id: 'c', name: 'c', prices: [_option('ដប', 1)]));

    expect(await shop.lastUsedCategoryId(), _drinks);
  });

  test('price settings fall back to the defaults without a row', () async {
    final settings = await repo('s1').priceSettings();
    expect(settings.useWholesale, isFalse);
    expect(settings.useCost, isTrue);
    expect(settings.currency, Currency.khr);
    expect(settings.khrPerUsd, 4000);

    await db.into(db.shopSettingsTable).insert(
      ShopSettingsTableCompanion.insert(
        shopId: 's1',
        useWholesalePrice: const Value(true),
        defaultCurrency: const Value('USD'),
        khrPerUsd: const Value(4100),
      ),
    );
    final saved = await repo('s1').priceSettings();
    expect(saved.useWholesale, isTrue);
    expect(saved.currency, Currency.usd);
    expect(saved.khrPerUsd, 4100);
  });

  test('the stand-in shop gets the starter categories once', () async {
    final shop = repo('local-u1', syncs: false);
    await shop.seedStarterCategories();
    await shop.seedStarterCategories();

    final categories = await shop.watchCategories().first;
    expect(categories.map((c) => c.name).toList(), [
      for (final (name, _) in starterCategories) name,
    ]);
    final drinks = categories.firstWhere((c) => c.name == 'ភេសជ្ជៈ');
    expect(
      drinks.units.map((u) => u.unit),
      unorderedEquals(['ដប', 'កំប៉ុង', 'កេះ']),
    );
    expect(await jobs(), isEmpty);
  });

  test('a shop with categories, or a server shop, is never seeded', () async {
    final local = repo('local-u1', syncs: false);
    await local.saveCategory(const ItemCategory(id: 'mine', name: 'Mine'));
    await local.seedStarterCategories();
    expect(await local.watchCategories().first, hasLength(1));

    final server = repo('s1');
    await server.seedStarterCategories();
    expect(await server.watchCategories().first, isEmpty);
  });

  test('the owner saves settings; a watch sees them and a job is queued',
      () async {
    var now = DateTime.utc(2026, 10, 19, 3);
    final shop = ItemRepository(
      ItemDao(db),
      _Scope('s1'),
      engine,
      connectivity,
      clock: () => now,
    );
    final seen = <PriceSettings>[];
    final sub = shop.watchPriceSettings().listen(seen.add);
    addTearDown(sub.cancel);

    final result = await shop.savePriceSettings(
      const PriceSettings(
        useWholesale: true,
        currency: Currency.usd,
        khrPerUsd: 4100,
        showConverted: false,
      ),
    );
    await Future<void>.delayed(Duration.zero);

    expect(result, isA<Ok<PriceSettings>>());
    final saved = seen.last;
    expect(
      (saved.useWholesale, saved.currency, saved.khrPerUsd, saved.showConverted),
      (true, Currency.usd, 4100, false),
    );
    expect(saved.rateUpdatedAt!.toUtc(), now, reason: 'the rate changed');
    expect(saved.rateUpdatedBy, 'u1');
    expect((await jobs()).single.entityType, SyncEntityType.shopSettings);

    // Saving the same rate again leaves "last edited" alone.
    now = now.add(const Duration(days: 1));
    await shop.savePriceSettings(saved.copyWith(useCost: false));
    await Future<void>.delayed(Duration.zero);
    expect(seen.last.rateUpdatedAt!.toUtc(), DateTime.utc(2026, 10, 19, 3));
  });

  test('only the owner may change shop settings', () async {
    final editor = ItemRepository(
      ItemDao(db),
      _Scope('s1', role: MemberRole.editor),
      engine,
      connectivity,
    );
    final result = await editor.savePriceSettings(
      const PriceSettings(useWholesale: true),
    );
    expect(result, isA<Err<PriceSettings>>());
    expect((await editor.priceSettings()).useWholesale, isFalse);
  });

  test('a syncing shop queues a job per write', () async {
    final shop = repo('s1');
    await shop.saveItem(
      Item(id: 'coke', name: 'Coca-Cola', prices: [_option('ដប', 3000)]),
    );
    await shop.deleteItem('coke');

    final queued = await jobs();
    expect(queued.single.entityType, SyncEntityType.item);
    expect(queued.single.operation, SyncOperation.delete);
  });

  test('the stand-in shop queues nothing', () async {
    final shop = repo('local-u1', syncs: false);
    await shop.saveItem(
      Item(id: 'coke', name: 'Coca-Cola', prices: [_option('ដប', 3000)]),
    );
    expect(await jobs(), isEmpty);
    expect(await shop.watchItems().first, hasLength(1));
  });
}
