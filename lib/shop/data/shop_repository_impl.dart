import 'package:jabhouy/app/app.dart';
import 'package:jabhouy/shop/shop.dart';
import 'package:jabhouy_core/jabhouy_core.dart';
import 'package:jabhouy_sync/jabhouy_sync.dart';

/// Local-first shop writes: the database is written first and always, and
/// a job describing the write goes into the outbox in the same breath.
///
/// What this no longer contains is a drain loop. Deciding when to retry,
/// how long to wait and when to stop is [SyncEngine]'s job, and it is the
/// same job for every feature — which is why four near-identical copies of
/// it existed before.
class DefaultShopRepository implements ShopRepository {
  const DefaultShopRepository(
    this._dao,
    this._api,
    this._engine,
    this._connectivity,
  );

  final ShopDao _dao;
  // Reads still go straight out and back: a pull has nothing to queue, so
  // it does not belong in the outbox.
  final ShopApi _api;
  final SyncEngine _engine;
  final ConnectivityService _connectivity;

  static const _offlineWrite =
      'Saved offline. It will sync when you are back online.';
  static const _offlineDelete =
      'Deleted offline. It will sync when you are back online.';

  @override
  Stream<List<ShopItemModel>> watchItems({
    String searchQuery = '',
    CategoryItemModel? categoryFilter,
  }) {
    return _dao.watchItems(
      searchQuery: searchQuery,
      categoryFilter: categoryFilter,
    );
  }

  @override
  Future<bool> hasCachedItems({
    String searchQuery = '',
    CategoryItemModel? categoryFilter,
  }) {
    return _dao.hasCachedItems(
      searchQuery: searchQuery,
      categoryFilter: categoryFilter,
    );
  }

  @override
  Future<ApiResponse<PaginatedResponse<ShopItemModel>>> refreshItems({
    int page = 1,
    int limit = 10,
    String searchQuery = '',
    String categoryFilter = '',
  }) async {
    if (!await _connectivity.isOnline) {
      return ApiResponse(
        success: false,
        message: 'Offline - showing cached data.',
      );
    }

    final response = await _api.fetchItems(
      page: page,
      limit: limit,
      searchQuery: searchQuery,
      categoryFilter: categoryFilter,
    );

    final data = response.data;
    if (response.success && data != null) {
      await _dao.cacheServerItems(data.items);
    }

    return response;
  }

  @override
  Future<ApiResponse<ShopItemModel?>> createItem(ShopItemModel body) async {
    // Phase 3's UUID `localId` column replaces this. Until then a negative
    // id marks "the server has never seen this row", which is what the
    // shop adapter branches on.
    final id = body.id == 0
        ? -(DateTime.now().millisecondsSinceEpoch % 1000000)
        : body.id;
    final localItem = body.copyWith(id: id, syncStatus: SyncStatus.pending);

    await _dao.insertPending(localItem);
    await _enqueue(localItem, SyncOperation.create, 'create');

    return _afterLocalWrite(data: localItem, offlineMessage: _offlineWrite);
  }

  @override
  Future<ApiResponse<ShopItemModel?>> updateItem(ShopItemModel body) async {
    final updatedAt = DateTime.now();
    final localItem = body.copyWith(
      updatedAt: updatedAt,
      syncStatus: SyncStatus.pending,
      isDeleted: false,
    );

    await _dao.replace(localItem, SyncStatus.pending);
    // The key varies per edit. Two edits before the first is sent still
    // collapse to one job — the outbox's unique key does that — but an
    // edit made after a push succeeded is a genuinely new write and must
    // not be mistaken for a replay of the one already delivered.
    await _enqueue(
      localItem,
      SyncOperation.update,
      'update:${updatedAt.microsecondsSinceEpoch}',
    );

    return _afterLocalWrite(
      data: body,
      offlineData: localItem,
      offlineMessage: _offlineWrite,
    );
  }

  @override
  Future<ApiResponse<dynamic>> deleteItem(ShopItemModel body) async {
    await _dao.markDeletedPending(body.id);
    await _enqueue(body, SyncOperation.delete, 'delete');

    return _afterLocalWrite<dynamic>(
      data: null,
      offlineMessage: _offlineDelete,
    );
  }

  @override
  Future<void> syncPendingChanges() async {
    if (!await _connectivity.isOnline) return;
    await _engine.drain();
  }

  Future<void> _enqueue(
    ShopItemModel item,
    SyncOperation operation,
    String keySuffix,
  ) {
    final categoryId = item.category?.id;
    return _engine.enqueue(
      entityType: SyncEntityType.shopItem,
      localId: '${item.id}',
      operation: operation,
      idempotencyKey: 'shopItem:${item.id}:$keySuffix',
      // An item filed under a category created offline must not reach the
      // server first. Category has no adapter yet, so nothing is queued
      // under that id and this is inert; it becomes load-bearing the day
      // category is layered, with no change here.
      dependsOnLocalId:
          categoryId != null && categoryId < 0 ? '$categoryId' : null,
    );
  }

  /// Every write takes the same shape after the local row and its job
  /// land: drain if online, otherwise report the row as saved and leave
  /// the job queued.
  Future<ApiResponse<T>> _afterLocalWrite<T>({
    required T data,
    required String offlineMessage,
    T? offlineData,
  }) async {
    if (await _connectivity.isOnline) {
      await _engine.drain();
      return ApiResponse(success: true, data: data);
    }

    return ApiResponse(
      success: true,
      data: offlineData ?? data,
      message: offlineMessage,
    );
  }
}
