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
  _Scope(this.shopId, {this.syncs = true});

  @override
  final String shopId;
  @override
  final bool syncs;
  @override
  MemberRole get role => MemberRole.owner;
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
