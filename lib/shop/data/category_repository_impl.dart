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

  @override
  Stream<List<CategoryItemModel>> watchCategories() => _dao.watchCategories();

  @override
  Future<Result<List<CategoryItemModel>>> refreshCategories() async {
    if (!await _connectivity.isOnline) {
      return const Err(AppException('Offline - showing cached data.'));
    }

    final result = await _api.fetchCategories();
    if (result case Ok(:final value)) {
      await _dao.cacheServerCategories(value);
    }

    return result;
  }

  @override
  Future<Result<CategoryItemModel>> createCategory(
    CategoryItemModel body,
  ) async {
    final id = body.id == 0
        ? -(DateTime.now().millisecondsSinceEpoch % 1000000)
        : body.id;
    final local = body.copyWith(id: id, syncStatus: SyncStatus.pending);

    await _dao.insertPending(local);
    await _enqueue(local, SyncOperation.create, 'create');

    return _settle(local);
  }

  @override
  Future<Result<CategoryItemModel>> updateCategory(
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

    return _settle(local);
  }

  @override
  Future<Result<void>> deleteCategory(CategoryItemModel body) async {
    await _dao.markDeletedPending(body.id);
    await _enqueue(body, SyncOperation.delete, 'delete');

    if (await _connectivity.isOnline) await _engine.drain();
    return const Ok<void>(null);
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

  /// See `DefaultShopRepository._settle`: the returned `syncStatus` is
  /// the honest answer to "did that reach the server?", and the `ui`
  /// layer picks its message from it.
  Future<Result<CategoryItemModel>> _settle(CategoryItemModel local) async {
    if (!await _connectivity.isOnline) return Ok(local);

    await _engine.drain();
    final after = await _dao.findById(local.id);
    return Ok(after ?? local.copyWith(syncStatus: SyncStatus.synced));
  }
}
