// Two phones and one in-memory server: what A writes, B pulls.
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jabhouy_core/jabhouy_core.dart';
import 'package:jabhouy_net/jabhouy_net.dart';
import 'package:jabhouy_shop/jabhouy_shop.dart';
import 'package:jabhouy_sync/jabhouy_sync.dart';
import 'package:mocktail/mocktail.dart';

class _Connectivity extends Mock implements ConnectivityService {}

class _Scope implements ShopScope {
  _Scope(this.userId);

  @override
  final String userId;
  @override
  String get shopId => 's1';
  @override
  MemberRole get role => MemberRole.owner;
  @override
  bool get syncs => true;
}

class _Phone {
  _Phone(String userId, ShopSyncApi api, {required bool online}) {
    final scope = _Scope(userId);
    final dao = ItemDao(db);
    final connectivity = _Connectivity();
    when(() => connectivity.isOnline).thenAnswer((_) async => online);
    engine = SyncEngine(
      database: db,
      transport: AdapterSyncTransport([
        ItemSyncAdapter(dao, api, () => scope.shopId),
        ItemCategorySyncAdapter(dao, api, () => scope.shopId),
        ShopSettingsSyncAdapter(dao, api),
      ]),
      changesSource: api,
      changeAppliers: [
        ItemCategoryChangeApplier(dao),
        ItemChangeApplier(dao),
        ShopSettingsChangeApplier(dao),
      ],
    );
    repo = ItemRepository(dao, scope, engine, connectivity);
  }

  final db = AppDatabase(NativeDatabase.memory());
  late final SyncEngine engine;
  late final ItemRepository repo;

  Future<List<Item>> items() => repo.watchItems().first;
}

PriceOption _price(String unit, int? price) =>
    PriceOption(id: newId(), unit: unit, currency: Currency.khr, price: price);

void main() {
  // Each phone is its own in-memory database.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late InMemoryShopSyncApi api;
  late _Phone a;
  late _Phone b;

  setUp(() {
    api = InMemoryShopSyncApi();
    a = _Phone('ua', api, online: true);
    b = _Phone('ub', api, online: true);
  });

  tearDown(() async {
    await a.db.close();
    await b.db.close();
  });

  test('an item, its category and the settings reach the other phone', () async {
    await a.repo.saveCategory(const ItemCategory(id: 'drinks', name: 'ភេសជ្ជៈ'));
    await a.repo.saveItem(
      Item(
        id: 'coke',
        name: 'Coca-Cola',
        nicknames: const ['កូកា'],
        categoryId: 'drinks',
        prices: [_price('ដប', 3000), _price('កេះ', null)],
      ),
    );
    await a.repo.savePriceSettings(const PriceSettings(khrPerUsd: 4100));
    await a.engine.drain();

    await b.engine.pullShop('s1');

    final item = (await b.items()).single;
    expect(item.name, 'Coca-Cola');
    expect(item.nicknames, ['កូកា']);
    expect(item.categoryId, 'drinks');
    expect(item.prices.map((p) => p.price), [3000, null], reason: 'no 0');
    expect((await b.repo.watchCategories().first).single.name, 'ភេសជ្ជៈ');
    expect((await b.repo.watchPriceSettings().first).khrPerUsd, 4100);
  });

  test('a delete on one phone hides the item on the other', () async {
    await a.repo.saveItem(Item(id: 'coke', name: 'Coke', prices: [_price('ដប', 1)]));
    await a.engine.drain();
    await b.engine.pullShop('s1');
    expect(await b.items(), hasLength(1));

    await a.repo.deleteItem('coke');
    await a.engine.drain();
    await b.engine.pullShop('s1');

    expect(await b.items(), isEmpty);
  });

  test('offline writes wait in the outbox, then arrive once online', () async {
    final offline = _Phone('uc', api, online: false);
    addTearDown(offline.db.close);
    await offline.repo.saveItem(
      Item(id: 'rice', name: 'អង្ករ', prices: [_price('គីឡូ', 3800)]),
    );
    expect(api.writes, isEmpty, reason: 'nothing left the phone');
    expect((await offline.items()).single.name, 'អង្ករ');

    await offline.engine.drain();
    await b.engine.pullShop('s1');

    expect((await b.items()).single.id, 'rice');
  });

  test('a pull does not overwrite an item with a queued local edit', () async {
    await a.repo.saveItem(Item(id: 'coke', name: 'Coke', prices: [_price('ដប', 1)]));
    await a.engine.drain();
    await b.engine.pullShop('s1');

    // B edits offline; A's later edit reaches the server first.
    final offlineB = _Phone('ub', api, online: false);
    addTearDown(offlineB.db.close);
    await api.put('s1', SyncEntityType.item, 'coke', {
      'name': 'Coke (A)',
      'nicknames': <String>[],
      'prices': <Object?>[],
    });
    await offlineB.repo.saveItem(
      Item(id: 'coke', name: 'Coke (B)', prices: [_price('ដប', 2)]),
    );
    api.failures.add(const AppException.network('offline'));

    await offlineB.engine.pullShop('s1');

    expect((await offlineB.items()).single.name, 'Coke (B)');
  });

  test('a viewer role refused by the server shows the server copy', () async {
    await a.repo.saveItem(Item(id: 'coke', name: 'Coke', prices: [_price('ដប', 1)]));
    await a.engine.drain();
    await b.engine.pullShop('s1');

    await b.repo.saveItem(Item(id: 'coke', name: 'Coke edited', prices: [_price('ដប', 9)]));
    api.failures.add(ShopApiException.forbiddenRole);
    final notices = <SyncNotice>[];
    b.engine.notices.listen(notices.add);

    await b.engine.drain();
    await b.engine.pullShop('s1');

    expect((await b.items()).single.name, 'Coke', reason: "the server's copy");
    expect(notices, [SyncNotice.noPermission]);
  });
}
