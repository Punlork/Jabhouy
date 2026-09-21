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
import 'package:mocktail/mocktail.dart';

class MockShopApi extends Mock implements ShopApi {}

class MockConnectivityService extends Mock implements ConnectivityService {}

void main() {
  late AppDatabase db;
  late ShopDao dao;
  late MockShopApi api;
  late MockConnectivityService connectivity;
  late DefaultShopRepository repository;

  setUpAll(() {
    registerFallbackValue(const ShopItemModel(id: 0, name: 'fallback'));
  });

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    dao = ShopDao(db);
    api = MockShopApi();
    connectivity = MockConnectivityService();
    repository = DefaultShopRepository(dao, api, connectivity);
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
  });

  test('a create the server rejects stays queued, not lost', () async {
    goOnline();
    when(() => api.createItem(any())).thenAnswer(
      (_) async => ApiResponse(success: false, message: 'server said no'),
    );

    await repository.createItem(const ShopItemModel(id: 0, name: 'Coffee'));

    final saved = (await rows()).single;
    expect(saved.id, lessThan(0));
    expect(saved.syncStatus, SyncStatus.failed);
  });

  test('a delete the server rejects stays on the device', () async {
    goOnline();
    await dao.cacheServerItems([const ShopItemModel(id: 7, name: 'Tea')]);
    when(() => api.deleteItem(7))
        .thenAnswer((_) async => ApiResponse<dynamic>(success: false));

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
}
