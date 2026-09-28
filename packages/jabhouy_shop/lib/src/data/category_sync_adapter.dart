import 'package:jabhouy_core/jabhouy_core.dart';
import 'package:jabhouy_shop/jabhouy_shop.dart';
import 'package:jabhouy_sync/jabhouy_sync.dart';

/// Sends category outbox jobs, and applies the answer to the local row.
class CategorySyncAdapter implements FeatureSyncAdapter, FeaturePullAdapter {
  const CategorySyncAdapter(this._dao, this._api);

  final CategoryDao _dao;
  final CategoryApi _api;

  @override
  SyncEntityType get entityType => SyncEntityType.category;

  /// Categories come back as one unpaged list, so a successful fetch is
  /// the whole list.
  @override
  Future<Result<void>> pullAll() async {
    switch (await _api.fetchCategories(quiet: true)) {
      case Ok(:final value):
        await _dao.reconcileServerCategories(value, complete: true);
        return const Ok(null);
      case Err(:final error):
        return Err(error);
    }
  }

  @override
  Future<SyncPushOutcome> push(OutboxEntry entry) async {
    final id = int.tryParse(entry.localId);
    if (id == null) {
      return SyncPushRejected('Unparseable category id "${entry.localId}"');
    }

    return switch (entry.operation) {
      SyncOperation.delete => _pushDelete(id),
      SyncOperation.create => _pushCreate(id),
      SyncOperation.update => _pushUpdate(id),
    };
  }

  Future<SyncPushOutcome> _pushDelete(int id) async {
    if (id < 0) {
      await _dao.purge(id);
      return const SyncPushSucceeded();
    }

    final result = await _api.deleteCategory(id);
    if (result.isOk || result.errorOrNull?.statusCode == 404) {
      await _dao.purge(id);
      return const SyncPushSucceeded();
    }

    return _fail(id, result.errorOrNull!);
  }

  Future<SyncPushOutcome> _pushCreate(int id) async {
    final category = await _dao.findById(id);
    if (category == null) return const SyncPushSucceeded();

    return switch (await _api.createCategory(category)) {
      Ok(:final value) => () async {
          await _dao.reconcileCreated(localId: id, serverCategory: value);
          return SyncPushSucceeded(serverId: '${value.id}');
        }(),
      Err(:final error) => _fail(id, error),
    };
  }

  Future<SyncPushOutcome> _pushUpdate(int id) async {
    final category = await _dao.findById(id);
    if (category == null) return const SyncPushSucceeded();

    return switch (await _api.updateCategory(category)) {
      Ok(:final value) => () async {
          await _dao.replace(value, SyncStatus.synced);
          return const SyncPushSucceeded();
        }(),
      Err(:final error) => _fail(id, error),
    };
  }

  Future<SyncPushOutcome> _fail(int id, AppException error) async {
    final outcome = outcomeFor(error);
    if (outcome is SyncPushRejected) {
      await _dao.markFailed(id);
    }
    return outcome;
  }
}
