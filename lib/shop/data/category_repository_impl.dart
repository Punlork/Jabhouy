import 'package:jabhouy/app/app.dart';
import 'package:jabhouy/shop/shop.dart';
import 'package:jabhouy_core/jabhouy_core.dart';
import 'package:jabhouy_sync/jabhouy_sync.dart';

/// Local-first category writes, queued through the same outbox as shop.
///
/// Sharing one engine is the point: a shop item that depends on a category
/// can only be ordered after it if both are jobs in the same queue.
class DefaultCategoryRepository implements CategoryRepository {
  const DefaultCategoryRepository(
    this._dao,
    this._api,
    this._engine,
    this._connectivity,
  );

  final CategoryDao _dao;
  final CategoryApi _api;
  final SyncEngine _engine;
  final ConnectivityService _connectivity;

  static const _offlineWrite =
      'Saved offline. It will sync when you are back online.';
  static const _offlineDelete =
      'Deleted offline. It will sync when you are back online.';

  @override
  Stream<List<CategoryItemModel>> watchCategories() => _dao.watchCategories();

  @override
  Future<ApiResponse<List<CategoryItemModel>>> refreshCategories() async {
    if (!await _connectivity.isOnline) {
      return ApiResponse(
        success: false,
        message: 'Offline - showing cached data.',
      );
    }

    final response = await _api.fetchCategories();
    final data = response.data;
    if (response.success && data != null) {
      await _dao.cacheServerCategories(data);
    }

    return response;
  }

  @override
  Future<ApiResponse<CategoryItemModel?>> createCategory(
    CategoryItemModel body,
  ) async {
    final id = body.id == 0
        ? -(DateTime.now().millisecondsSinceEpoch % 1000000)
        : body.id;
    final local = body.copyWith(id: id, syncStatus: SyncStatus.pending);

    await _dao.insertPending(local);
    await _enqueue(local, SyncOperation.create, 'create');

    return _afterLocalWrite(data: local, offlineMessage: _offlineWrite);
  }

  @override
  Future<ApiResponse<CategoryItemModel?>> updateCategory(
    CategoryItemModel body,
  ) async {
    final local = body.copyWith(
      syncStatus: SyncStatus.pending,
      isDeleted: false,
    );

    await _dao.replace(local, SyncStatus.pending);
    // Categories carry no updatedAt, so the clock supplies what makes one
    // edit distinguishable from a replay of the last.
    await _enqueue(
      local,
      SyncOperation.update,
      'update:${DateTime.now().microsecondsSinceEpoch}',
    );

    return _afterLocalWrite(
      data: body,
      offlineData: local,
      offlineMessage: _offlineWrite,
    );
  }

  @override
  Future<ApiResponse<dynamic>> deleteCategory(CategoryItemModel body) async {
    await _dao.markDeletedPending(body.id);
    await _enqueue(body, SyncOperation.delete, 'delete');

    return _afterLocalWrite<dynamic>(
      data: null,
      offlineMessage: _offlineDelete,
    );
  }

  Future<void> _enqueue(
    CategoryItemModel category,
    SyncOperation operation,
    String keySuffix,
  ) {
    return _engine.enqueue(
      entityType: SyncEntityType.category,
      localId: '${category.id}',
      operation: operation,
      idempotencyKey: 'category:${category.id}:$keySuffix',
    );
  }

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
