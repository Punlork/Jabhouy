import 'package:jabhouy/app/app.dart';
import 'package:jabhouy/shop/shop.dart';
import 'package:jabhouy_core/jabhouy_core.dart';
import 'package:jabhouy_sync/jabhouy_sync.dart';

/// Sends category outbox jobs, and applies the answer to the local row.
class CategorySyncAdapter implements FeatureSyncAdapter {
  const CategorySyncAdapter(this._dao, this._api);

  final CategoryDao _dao;
  final CategoryApi _api;

  @override
  SyncEntityType get entityType => SyncEntityType.category;

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

    final response = await _api.deleteCategory(id);
    if (response.success || response.statusCode == 404) {
      await _dao.purge(id);
      return const SyncPushSucceeded();
    }

    return _fail(id, response.statusCode, response.message);
  }

  Future<SyncPushOutcome> _pushCreate(int id) async {
    final category = await _dao.findById(id);
    if (category == null) return const SyncPushSucceeded();

    final response = await _api.createCategory(category);
    final created = response.data;
    if (response.success && created != null) {
      await _dao.reconcileCreated(localId: id, serverCategory: created);
      return SyncPushSucceeded(serverId: '${created.id}');
    }

    return _fail(id, response.statusCode, response.message);
  }

  Future<SyncPushOutcome> _pushUpdate(int id) async {
    final category = await _dao.findById(id);
    if (category == null) return const SyncPushSucceeded();

    final response = await _api.updateCategory(category);
    final updated = response.data;
    if (response.success && updated != null) {
      await _dao.replace(updated, SyncStatus.synced);
      return const SyncPushSucceeded();
    }

    return _fail(id, response.statusCode, response.message);
  }

  Future<SyncPushOutcome> _fail(
    int id,
    int? statusCode,
    String? message,
  ) async {
    final outcome = outcomeFor(
      success: false,
      statusCode: statusCode,
      message: message,
    );
    if (outcome is SyncPushRejected) {
      await _dao.markFailed(id);
    }
    return outcome;
  }
}
