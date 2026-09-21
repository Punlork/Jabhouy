import 'package:jabhouy/app/app.dart';
import 'package:jabhouy/shop/shop.dart';
import 'package:jabhouy_core/jabhouy_core.dart';

/// Local-first shop writes: the database is written first and always, the
/// server is told afterwards and only when there is a connection.
class DefaultShopRepository implements ShopRepository {
  const DefaultShopRepository(this._dao, this._api, this._connectivity);

  final ShopDao _dao;
  final ShopApi _api;
  final ConnectivityService _connectivity;

  static const _offlineCreate =
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
    // Phase 3 replaces this with a UUID `localId` column. Until then a
    // negative id marks "the server has never seen this row", which is what
    // the drain loop below branches on.
    final id = body.id == 0
        ? -(DateTime.now().millisecondsSinceEpoch % 1000000)
        : body.id;
    final localItem = body.copyWith(id: id, syncStatus: SyncStatus.pending);

    await _dao.insertPending(localItem);

    return _afterLocalWrite(
      data: localItem,
      offlineMessage: _offlineCreate,
    );
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

    return _afterLocalWrite(
      data: body,
      offlineData: localItem,
      offlineMessage: _offlineCreate,
    );
  }

  @override
  Future<ApiResponse<dynamic>> deleteItem(ShopItemModel body) async {
    await _dao.markDeletedPending(body.id);

    return _afterLocalWrite<dynamic>(
      data: null,
      offlineMessage: _offlineDelete,
    );
  }

  @override
  Future<void> syncPendingChanges() async {
    if (!await _connectivity.isOnline) return;

    for (final item in await _dao.pendingItems()) {
      try {
        await _push(item);
      } catch (_) {
        await _dao.markFailed(item.id);
      }
    }
  }

  /// Every write takes the same shape after the local row lands: drain if
  /// online, otherwise report the row as saved and leave it queued.
  Future<ApiResponse<T>> _afterLocalWrite<T>({
    required T data,
    required String offlineMessage,
    T? offlineData,
  }) async {
    if (await _connectivity.isOnline) {
      await syncPendingChanges();
      return ApiResponse(success: true, data: data);
    }

    return ApiResponse(
      success: true,
      data: offlineData ?? data,
      message: offlineMessage,
    );
  }

  Future<void> _push(ShopItemModel item) async {
    if (item.isDeleted) {
      // A row the server never saw needs no DELETE; it only has to stop
      // existing here.
      if (item.id < 0) {
        await _dao.purge(item.id);
        return;
      }

      // The old drain loop discarded this response and reported success
      // unconditionally, so a delete the server rejected was forgotten and
      // the item reappeared on the next pull.
      final response = await _api.deleteItem(item.id);
      if (response.success) {
        await _dao.purge(item.id);
      } else {
        await _dao.markFailed(item.id);
      }
      return;
    }

    if (item.id < 0) {
      final response = await _api.createItem(item);
      final created = response.data;
      if (response.success && created != null) {
        await _dao.reconcileCreated(localId: item.id, serverItem: created);
      } else {
        await _dao.markFailed(item.id);
      }
      return;
    }

    final response = await _api.updateItem(item);
    final updated = response.data;
    if (response.success && updated != null) {
      await _dao.replace(updated, SyncStatus.synced);
    } else {
      await _dao.markFailed(item.id);
    }
  }
}
