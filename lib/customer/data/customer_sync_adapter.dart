import 'package:jabhouy/app/app.dart';
import 'package:jabhouy/customer/customer.dart';
import 'package:jabhouy_core/jabhouy_core.dart';
import 'package:jabhouy_sync/jabhouy_sync.dart';

/// Sends customer outbox jobs, and applies the answer to the local row.
class CustomerSyncAdapter implements FeatureSyncAdapter {
  const CustomerSyncAdapter(this._dao, this._api);

  final CustomerDao _dao;
  final CustomerApi _api;

  @override
  SyncEntityType get entityType => SyncEntityType.customer;

  @override
  Future<SyncPushOutcome> push(OutboxEntry entry) async {
    final id = int.tryParse(entry.localId);
    if (id == null) {
      return SyncPushRejected('Unparseable customer id "${entry.localId}"');
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

    final response = await _api.deleteCustomer(id);
    if (response.success || response.statusCode == 404) {
      await _dao.purge(id);
      return const SyncPushSucceeded();
    }

    return _fail(id, response.statusCode, response.message);
  }

  Future<SyncPushOutcome> _pushCreate(int id) async {
    final customer = await _dao.findById(id);
    if (customer == null) return const SyncPushSucceeded();

    final response = await _api.createCustomer(customer);
    final created = response.data;
    if (response.success && created != null) {
      await _dao.reconcileCreated(localId: id, serverCustomer: created);
      return SyncPushSucceeded(serverId: '${created.id}');
    }

    return _fail(id, response.statusCode, response.message);
  }

  Future<SyncPushOutcome> _pushUpdate(int id) async {
    final customer = await _dao.findById(id);
    if (customer == null) return const SyncPushSucceeded();

    final response = await _api.updateCustomer(customer);
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
