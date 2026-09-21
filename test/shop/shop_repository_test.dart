// Phase 2 of the architecture restructure: the shop slice.
//
// These run against a real in-memory database rather than a mocked DAO,
// because the defects this slice fixes are all about what is left in the
// rows after a push succeeds or fails. A mocked DAO would assert that the
// repository called the method it was written to call, which is not the
// same claim.
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jabhouy/app/app.dart';
import 'package:jabhouy/shop/shop.dart';
import 'package:jabhouy_core/jabhouy_core.dart';
import 'package:jabhouy_sync/jabhouy_sync.dart';
import 'package:mocktail/mocktail.dart';

class MockShopApi extends Mock implements ShopApi {}

class MockConnectivityService extends Mock implements ConnectivityService {}

void main() {
  late AppDatabase db;
  late ShopDao dao;
  late MockShopApi api;
  late MockConnectivityService connectivity;
  late SyncEngine engine;
  late DefaultShopRepository repository;

  setUpAll(() {
    registerFallbackValue(const ShopItemModel(id: 0, name: 'fallback'));
  });

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    dao = ShopDao(db);
    api = MockShopApi();
    connectivity = MockConnectivityService();
    // A real engine over the same in-memory database, not a double: the
    // point of these tests is the whole chain, repository to outbox to
    // adapter to (faked) HTTP and back onto the row.
    engine = SyncEngine(
      database: db,
      transport: AppSyncTransport([ShopSyncAdapter(dao, api)]),
    );
    repository = DefaultShopRepository(dao, api, engine, connectivity);
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

  Future<List<ShopItem>> rows() => db.select(db.shopItems).get();

  Future<List<OutboxEntry>> jobs() => db.select(db.outboxEntries).get();

  /// Echoes back whatever was sent, with the id and status the server
  /// would have assigned.
  ApiResponse<ShopItemModel?> echo(Invocation invocation, {int? id}) {
    final sent = invocation.positionalArguments.first as ShopItemModel;
    return ApiResponse(
      success: true,
      data: sent.copyWith(id: id ?? sent.id, syncStatus: SyncStatus.synced),
    );
  }

  test('a create made offline is queued locally and nothing is pushed',
      () async {
    goOffline();

    final response =
        await repository.createItem(const ShopItemModel(id: 0, name: 'Coffee'));

    expect(response.success, isTrue);
    expect(response.message, contains('offline'));

    final saved = (await rows()).single;
    expect(saved.name, 'Coffee');
    expect(saved.id, lessThan(0), reason: 'minted a local id');
    expect(saved.syncStatus, SyncStatus.pending);
    verifyNever(() => api.createItem(any()));

    final job = (await jobs()).single;
    expect(job.entityType, SyncEntityType.shopItem);
    expect(job.operation, SyncOperation.create);
    expect(job.localId, '${saved.id}');
  });

  test('a create made online reconciles to the id the server assigned',
      () async {
    goOnline();
    when(() => api.createItem(any()))
        .thenAnswer((invocation) async => echo(invocation, id: 42));

    await repository.createItem(const ShopItemModel(id: 0, name: 'Coffee'));

    final saved = (await rows()).single;
    expect(saved.id, 42, reason: 'the negative local row was swapped out');
    expect(saved.syncStatus, SyncStatus.synced);
    expect(await jobs(), isEmpty, reason: 'the job left the queue');
  });

  test('a create the server rejects stays queued, not lost', () async {
    goOnline();
    when(() => api.createItem(any())).thenAnswer(
      (_) async => ApiResponse(
        success: false,
        message: 'server said no',
        statusCode: 400,
      ),
    );

    await repository.createItem(const ShopItemModel(id: 0, name: 'Coffee'));

    final saved = (await rows()).single;
    expect(saved.id, lessThan(0));
    expect(saved.syncStatus, SyncStatus.failed);
  });

  test('a delete the server rejects stays on the device', () async {
    goOnline();
    await dao.cacheServerItems([const ShopItemModel(id: 7, name: 'Tea')]);
    when(() => api.deleteItem(7)).thenAnswer(
      (_) async => ApiResponse<dynamic>(success: false, statusCode: 400),
    );

    await repository.deleteItem(const ShopItemModel(id: 7, name: 'Tea'));

    // The old drain loop hard-coded `ApiResponse(success: true)` for the
    // delete branch, so a rejected delete was marked synced and the item
    // came back on the next pull.
    final saved = (await rows()).single;
    expect(saved.id, 7);
    expect(saved.isDeleted, isTrue);
    expect(saved.syncStatus, SyncStatus.failed);
  });

  test('a delete the server accepts removes the row', () async {
    goOnline();
    await dao.cacheServerItems([const ShopItemModel(id: 7, name: 'Tea')]);
    when(() => api.deleteItem(7))
        .thenAnswer((_) async => ApiResponse<dynamic>(success: true));

    await repository.deleteItem(const ShopItemModel(id: 7, name: 'Tea'));

    expect(await rows(), isEmpty);
  });

  test('deleting a row the server never saw does not call the server',
      () async {
    goOffline();
    await repository.createItem(const ShopItemModel(id: 0, name: 'Coffee'));
    final localId = (await rows()).single.id;

    goOnline();
    await repository.deleteItem(ShopItemModel(id: localId, name: 'Coffee'));

    expect(await rows(), isEmpty);
    verifyNever(() => api.deleteItem(any()));
  });

  test('an update made online lands as synced', () async {
    goOnline();
    await dao.cacheServerItems([const ShopItemModel(id: 7, name: 'Tea')]);
    when(() => api.updateItem(any()))
        .thenAnswer((invocation) async => echo(invocation));

    await repository.updateItem(const ShopItemModel(id: 7, name: 'Tea (L)'));

    final saved = (await rows()).single;
    expect(saved.name, 'Tea (L)');
    expect(saved.syncStatus, SyncStatus.synced);
  });

  test('watchItems hides deleted rows and honours the search query',
      () async {
    await dao.cacheServerItems([
      ShopItemModel(id: 1, name: 'Coffee', updatedAt: DateTime(2026, 9, 12)),
      ShopItemModel(id: 2, name: 'Tea', updatedAt: DateTime(2026, 9, 11)),
      ShopItemModel(id: 3, name: 'Cocoa', updatedAt: DateTime(2026, 9, 13)),
    ]);
    await dao.markDeletedPending(3);

    expect(
      (await repository.watchItems().first).map((i) => i.name),
      ['Coffee', 'Tea'],
    );
    expect(
      (await repository.watchItems(searchQuery: 'Te').first).map((i) => i.name),
      ['Tea'],
    );
  });

  // The four below exist only because the engine does. The old drain loop
  // could not express any of them: every failure became syncStatus = 2 and
  // stopped there.

  test('a 500 leaves the row pending and schedules another attempt',
      () async {
    goOnline();
    when(() => api.createItem(any())).thenAnswer(
      (_) async => ApiResponse(
        success: false,
        message: 'upstream exploded',
        statusCode: 500,
      ),
    );

    await repository.createItem(const ShopItemModel(id: 0, name: 'Coffee'));

    final saved = (await rows()).single;
    expect(
      saved.syncStatus,
      SyncStatus.pending,
      reason: 'still going to be retried, so not failed',
    );

    final job = (await jobs()).single;
    expect(job.attemptCount, 1);
    expect(job.lastError, contains('upstream exploded'));
    expect(job.nextAttemptAt.isAfter(DateTime.now()), isTrue);
  });

  test('a 400 stops the job and keeps its reason', () async {
    goOnline();
    when(() => api.createItem(any())).thenAnswer(
      (_) async => ApiResponse(
        success: false,
        message: 'name is required',
        statusCode: 400,
      ),
    );

    await repository.createItem(const ShopItemModel(id: 0, name: ''));

    expect((await rows()).single.syncStatus, SyncStatus.failed);
    final job = (await jobs()).single;
    expect(job.lastError, contains('name is required'));
  });

  test('two edits before the first is sent are one job', () async {
    goOffline();
    await dao.cacheServerItems([const ShopItemModel(id: 7, name: 'Tea')]);

    await repository.updateItem(const ShopItemModel(id: 7, name: 'Tea M'));
    await repository.updateItem(const ShopItemModel(id: 7, name: 'Tea L'));

    expect((await jobs()).length, 1, reason: 'folded by the unique key');
    expect((await rows()).single.name, 'Tea L');
  });

  test('a delete the server has already forgotten counts as done', () async {
    goOnline();
    await dao.cacheServerItems([const ShopItemModel(id: 7, name: 'Tea')]);
    when(() => api.deleteItem(7)).thenAnswer(
      (_) async => ApiResponse<dynamic>(success: false, statusCode: 404),
    );

    await repository.deleteItem(const ShopItemModel(id: 7, name: 'Tea'));

    expect(await rows(), isEmpty);
    expect(await jobs(), isEmpty);
  });
}
