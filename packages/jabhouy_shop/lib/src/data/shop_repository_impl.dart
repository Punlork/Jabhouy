import 'package:jabhouy_core/jabhouy_core.dart';
import 'package:jabhouy_net/jabhouy_net.dart';
import 'package:jabhouy_shop/jabhouy_shop.dart';
import 'package:jabhouy_sync/jabhouy_sync.dart';

/// Local-first shop writes: the database is written first and always, and
/// a job describing the write goes into the outbox in the same breath.
///
/// What this no longer contains is a drain loop. Deciding when to retry,
/// how long to wait and when to stop is [SyncEngine]'s job, and it is the
/// same job for every feature — which is why four near-identical copies of
/// it existed before.
class DefaultShopRepository implements ShopRepository {
  DefaultShopRepository(
    this._dao,
    this._api,
    this._engine,
    this._connectivity, {
    FeatureFlags flags = const FixedFeatureFlags({}),
  }) : _inBackground = flags.isEnabled(Feature.backgroundSync);

  /// Saves return after the local write and push in the background.
  final bool _inBackground;

  final ShopDao _dao;
  // Reads still go straight out and back: a pull has nothing to queue, so
  // it does not belong in the outbox.
  final ShopApi _api;
  final SyncEngine _engine;
  final ConnectivityService _connectivity;

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
  Future<Result<PaginatedResponse<ShopItemModel>>> refreshItems({
    int page = 1,
    int limit = 10,
    String searchQuery = '',
    String categoryFilter = '',
  }) async {
    if (!await _connectivity.isOnline) {
      return const Err(AppException('Offline - showing cached data.'));
    }

    final result = await _api.fetchItems(
      page: page,
      limit: limit,
      searchQuery: searchQuery,
      categoryFilter: categoryFilter,
    );

    if (result case Ok(:final value)) {
      await _dao.cacheServerItems(value.items);
    }

    return result;
  }

  @override
  Future<Result<ShopItemModel>> createItem(ShopItemModel body) async {
    // Phase 3's UUID `localId` column replaces this. Until then a negative
    // id marks "the server has never seen this row", which is what the
    // shop adapter branches on.
    final id = body.id == 0
        ? -(DateTime.now().millisecondsSinceEpoch % 1000000)
        : body.id;
    final localItem = body.copyWith(id: id, syncStatus: SyncStatus.pending);

    await _dao.insertPending(localItem);
    await _enqueue(localItem, SyncOperation.create, 'create');

    return _settle(localItem);
  }

  @override
  Future<Result<ShopItemModel>> updateItem(ShopItemModel body) async {
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

    return _settle(localItem);
  }

  @override
  Future<Result<void>> deleteItem(ShopItemModel body) async {
    await _dao.markDeletedPending(body.id);
    await _enqueue(body, SyncOperation.delete, 'delete');

    if (await _connectivity.isOnline) {
      if (_inBackground) {
        _engine.requestSync();
      } else {
        await _engine.drain();
      }
    }
    return const Ok<void>(null);
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

  /// Drains if there is a connection, then reports the row as it now
  /// stands.
  ///
  /// The returned `syncStatus` is the honest answer to "did that reach the
  /// server?", which is what the `ui` layer needs to pick a message — the
  /// repository no longer ships one. A row missing from under its local id
  /// was reconciled onto the server's, so it is synced; a row still there
  /// is pending or failed, and says which.
  Future<Result<ShopItemModel>> _settle(ShopItemModel local) async {
    if (!await _connectivity.isOnline) return Ok(local);
    if (_inBackground) {
      // The row is safe on the phone; the seller does not wait for the
      // server, and the list redraws when the push lands.
      _engine.requestSync();
      return Ok(local);
    }

    await _engine.drain();
    final after = await _dao.findById(local.id);
    return Ok(after ?? local.copyWith(syncStatus: SyncStatus.synced));
  }
}
