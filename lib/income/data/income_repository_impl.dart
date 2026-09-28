import 'package:jabhouy/income/data/api/income_api.dart';
import 'package:jabhouy/income/data/db/income_dao.dart';
import 'package:jabhouy/income/data/income_repository.dart';
import 'package:jabhouy/income/models/bank_notification_model.dart';
import 'package:jabhouy_core/jabhouy_core.dart';
import 'package:jabhouy_sync/jabhouy_sync.dart';

class DefaultIncomeRepository implements IncomeRepository {
  const DefaultIncomeRepository(this._dao, this._api, this._engine);

  final IncomeDao _dao;
  final IncomeApi _api;
  final SyncEngine _engine;

  @override
  Stream<List<BankNotificationModel>> watchNotifications({
    String searchQuery = '',
    DateTime? fromDate,
    DateTime? toDate,
    BankApp? bankFilter,
    NotificationRecordFilter recordFilter = NotificationRecordFilter.all,
  }) {
    return _dao.watchNotifications(
      searchQuery: searchQuery,
      fromDate: fromDate,
      toDate: toDate,
      bankFilter: bankFilter,
      recordFilter: recordFilter,
    );
  }

  @override
  Future<BankNotificationModel?> findByFingerprint(String fingerprint) =>
      _dao.findByFingerprint(fingerprint);

  @override
  Future<List<BankNotificationModel>> pendingNotifications() =>
      _dao.pendingNotifications();

  @override
  Future<Result<List<BankNotificationModel>>> fetchRemote() =>
      _api.fetchNotifications();

  @override
  Future<bool> store(
    BankNotificationModel model, {
    String? rawPayloadOverride,
  }) {
    return _dao.upsert(model, rawPayloadOverride: rawPayloadOverride);
  }

  @override
  Future<void> updateSyncStatus(String fingerprint, SyncStatus status) =>
      _dao.updateSyncStatus(fingerprint, status);

  @override
  Future<void> enqueueUpload(BankNotificationModel model) {
    // The fingerprint is both the local key and the idempotency key.
    // Income is the feature the outbox generalised from: the UNIQUE
    // constraint on BankNotifications.fingerprint is the guarantee the
    // other four features had to have one invented for.
    return _engine.enqueue(
      entityType: SyncEntityType.bankNotification,
      localId: model.fingerprint,
      operation: SyncOperation.create,
      idempotencyKey: model.fingerprint,
    );
  }

  @override
  Future<void> drainUploads() => _engine.drain();

  @override
  Future<int> backfillMetadata() async {
    final rows = await _dao.rowsNeedingBackfill();
    if (rows.isEmpty) return 0;

    var repaired = 0;
    for (final row in rows) {
      final candidate = BankNotificationModel.fromNativeMap({
        'fingerprint': row.fingerprint,
        'packageName': row.packageName,
        'title': row.title,
        'message': row.message,
        'receivedAt': row.receivedAt.millisecondsSinceEpoch,
        'source': row.source,
        'createdAt': row.createdAt.toIso8601String(),
      });

      final updateBank = row.bankKey == BankApp.unknown.key &&
          candidate.bankApp != BankApp.unknown;
      final updateAmount = row.amount == null && candidate.amount != null;
      final updateCurrency = updateAmount &&
          row.currency == 'USD' &&
          candidate.currency.isNotEmpty &&
          candidate.currency != row.currency;

      if (!updateBank && !updateAmount && !updateCurrency) continue;

      await _dao.applyBackfill(
        row.id,
        bankKey: updateBank ? Value(candidate.bankApp.key) : const Value.absent(),
        amount: updateAmount ? Value(candidate.amount) : const Value.absent(),
        currency:
            updateCurrency ? Value(candidate.currency) : const Value.absent(),
      );
      repaired++;
    }

    return repaired;
  }
}
