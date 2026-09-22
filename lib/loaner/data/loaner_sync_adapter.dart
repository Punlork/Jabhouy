import 'package:jabhouy/loaner/loaner.dart';
import 'package:jabhouy_core/jabhouy_core.dart';
import 'package:jabhouy_sync/jabhouy_sync.dart';

/// Sends loaner outbox jobs, and applies the answer to the local row.
class LoanerSyncAdapter implements FeatureSyncAdapter {
  const LoanerSyncAdapter(this._dao, this._api);

  final LoanerDao _dao;
  final LoanerApi _api;

  @override
  SyncEntityType get entityType => SyncEntityType.loaner;

  @override
  Future<SyncPushOutcome> push(OutboxEntry entry) async {
    final id = int.tryParse(entry.localId);
    if (id == null) {
      return SyncPushRejected('Unparseable loaner id "${entry.localId}"');
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

    final result = await _api.deleteLoaner(id);
    if (result.isOk || result.errorOrNull?.statusCode == 404) {
      await _dao.purge(id);
      return const SyncPushSucceeded();
    }

    return _fail(id, result.errorOrNull!);
  }

  Future<SyncPushOutcome> _pushCreate(int id) async {
    final loaner = await _dao.findById(id);
    if (loaner == null) return const SyncPushSucceeded();

    return switch (await _api.createLoaner(loaner)) {
      Ok(:final value) => () async {
          await _dao.reconcileCreated(localId: id, serverLoaner: value);
          return SyncPushSucceeded(serverId: '${value.id}');
        }(),
      Err(:final error) => _fail(id, error),
    };
  }

  Future<SyncPushOutcome> _pushUpdate(int id) async {
    final loaner = await _dao.findById(id);
    if (loaner == null) return const SyncPushSucceeded();

    return switch (await _api.updateLoaner(loaner)) {
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
