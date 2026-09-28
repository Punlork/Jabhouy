// The category slice, and the defect it is the only feature able to fix:
// a shop item reaching the server before the offline category it points
// at. That one needs two adapters in the same queue, which is why it
// could not be tested until now.
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jabhouy_core/jabhouy_core.dart';
import 'package:jabhouy_net/jabhouy_net.dart';
import 'package:jabhouy_shop/jabhouy_shop.dart';
import 'package:jabhouy_sync/jabhouy_sync.dart';
import 'package:mocktail/mocktail.dart';

class MockCategoryApi extends Mock implements CategoryApi {}

class MockShopApi extends Mock implements ShopApi {}

class MockConnectivityService extends Mock implements ConnectivityService {}

void main() {
  late AppDatabase db;
  late CategoryDao categoryDao;
  late ShopDao shopDao;
  late MockCategoryApi categoryApi;
  late MockShopApi shopApi;
  late MockConnectivityService connectivity;
  late SyncEngine engine;
  late DefaultCategoryRepository repository;

  setUpAll(() {
    registerFallbackValue(const CategoryItemModel(id: 0, name: 'fallback'));
    registerFallbackValue(const ShopItemModel(id: 0, name: 'fallback'));
  });

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    categoryDao = CategoryDao(db);
    shopDao = ShopDao(db);
    categoryApi = MockCategoryApi();
    shopApi = MockShopApi();
    connectivity = MockConnectivityService();
    engine = SyncEngine(
      database: db,
      transport: AdapterSyncTransport([
        ShopSyncAdapter(shopDao, shopApi),
        CategorySyncAdapter(categoryDao, categoryApi),
      ]),
    );
    repository = DefaultCategoryRepository(
      categoryDao,
      categoryApi,
      engine,
      connectivity,
    );
  });

  tearDown(() async {
    await db.close();
  });

  void goOnline() {
    when(() => connectivity.isOnline).thenAnswer((_) async => true);
  }

  void goOffline() {
    when(() => connectivity.isOnline).thenAnswer((_) async => false);
  }

  Future<List<Category>> categoryRows() => db.select(db.categories).get();
  Future<List<ShopItem>> itemRows() => db.select(db.shopItems).get();
  Future<List<OutboxEntry>> jobs() => db.select(db.outboxEntries).get();

  test('a create made offline is queued locally and nothing is pushed',
      () async {
    goOffline();

    await repository.createCategory(const CategoryItemModel(id: 0, name: 'Drinks'));

    final saved = (await categoryRows()).single;
    expect(saved.name, 'Drinks');
    expect(saved.id, lessThan(0));
    expect(saved.syncStatus, SyncStatus.pending);

    final job = (await jobs()).single;
    expect(job.entityType, SyncEntityType.category);
    expect(job.operation, SyncOperation.create);
    verifyNever(() => categoryApi.createCategory(any()));
  });

  test('a pull does not write over a category whose rename is queued',
      () async {
    await categoryDao.cacheServerCategories(
      const [CategoryItemModel(id: 4, name: 'Drinks')],
    );
    goOffline();
    await repository.updateCategory(
      const CategoryItemModel(id: 4, name: 'Cold drinks'),
    );

    await categoryDao.cacheServerCategories(
      const [CategoryItemModel(id: 4, name: 'Drinks')],
    );

    final row = await db.select(db.categories).getSingle();
    expect(row.name, 'Cold drinks');
  });

  test('a pull removes a category the server deleted', () async {
    await categoryDao.cacheServerCategories(const [
      CategoryItemModel(id: 4, name: 'Drinks'),
      CategoryItemModel(id: 5, name: 'Snacks'),
    ]);
    when(() => categoryApi.fetchCategories(quiet: true)).thenAnswer(
      (_) async => const Ok([CategoryItemModel(id: 4, name: 'Drinks')]),
    );

    await CategorySyncAdapter(categoryDao, categoryApi).pullAll();

    final rows = await db.select(db.categories).get();
    expect(rows.map((r) => r.name), ['Drinks']);
  });

  test('reconciling a category repoints the items that referenced it',
      () async {
    goOnline();
    when(() => categoryApi.createCategory(any())).thenAnswer(
      (i) async => Ok(
        (i.positionalArguments.first as CategoryItemModel)
            .copyWith(id: 9, syncStatus: SyncStatus.synced),
      ),
    );

    goOffline();
    await repository.createCategory(const CategoryItemModel(id: 0, name: 'Drinks'));
    final localId = (await categoryRows()).single.id;

    await shopDao.insertPending(
      ShopItemModel(
        id: -50,
        name: 'Cola',
        category: CategoryItemModel(id: localId, name: 'Drinks'),
      ),
    );

    goOnline();
    await engine.drain();

    expect((await categoryRows()).single.id, 9);
    expect(
      (await itemRows()).single.categoryId,
      9,
      reason: 'the item followed its category to the server id',
    );
  });

  test('an item never reaches the server before its offline category',
      () async {
    // Enqueued in the wrong order on purpose. Natural insertion order
    // would pass this test without any dependency logic at all.
    const categoryLocalId = -999;
    const itemLocalId = -50;

    await categoryDao.insertPending(
      const CategoryItemModel(id: categoryLocalId, name: 'Drinks'),
    );
    await shopDao.insertPending(
      const ShopItemModel(
        id: itemLocalId,
        name: 'Cola',
        category: CategoryItemModel(id: categoryLocalId, name: 'Drinks'),
      ),
    );

    await engine.enqueue(
      entityType: SyncEntityType.shopItem,
      localId: '$itemLocalId',
      operation: SyncOperation.create,
      idempotencyKey: 'shopItem:$itemLocalId:create',
      dependsOnLocalId: '$categoryLocalId',
    );
    await engine.enqueue(
      entityType: SyncEntityType.category,
      localId: '$categoryLocalId',
      operation: SyncOperation.create,
      idempotencyKey: 'category:$categoryLocalId:create',
    );

    when(() => categoryApi.createCategory(any())).thenAnswer(
      (i) async =>
          Ok((i.positionalArguments.first as CategoryItemModel).copyWith(id: 9)),
    );
    when(() => shopApi.createItem(any())).thenAnswer(
      (i) async =>
          Ok((i.positionalArguments.first as ShopItemModel).copyWith(id: 70)),
    );

    await engine.drain();

    verifyInOrder([
      () => categoryApi.createCategory(any()),
      () => shopApi.createItem(any()),
    ]);

    final item = (await itemRows()).single;
    expect(item.id, 70);
    expect(
      item.categoryId,
      9,
      reason: 'pushed with the server category id, not the local one',
    );
    expect(await jobs(), isEmpty);
  });

  test('a delete the server has already forgotten counts as done', () async {
    goOnline();
    await categoryDao.cacheServerCategories(
      [const CategoryItemModel(id: 4, name: 'Snacks')],
    );
    when(() => categoryApi.deleteCategory(4)).thenAnswer(
      (_) async => const Err(AppException('gone', statusCode: 404)),
    );

    await repository.deleteCategory(const CategoryItemModel(id: 4, name: 'Snacks'));

    expect(await categoryRows(), isEmpty);
    expect(await jobs(), isEmpty);
  });

  test('a 400 stops the job and marks the row failed', () async {
    goOnline();
    when(() => categoryApi.createCategory(any())).thenAnswer(
      (_) async => const Err(
        AppException('name already taken', statusCode: 400),
      ),
    );

    await repository.createCategory(const CategoryItemModel(id: 0, name: 'Drinks'));

    expect((await categoryRows()).single.syncStatus, SyncStatus.failed);
    expect((await jobs()).single.lastError, contains('name already taken'));
  });
}
