import 'package:jabhouy/income/data/db/income_dao.dart';
import 'package:jabhouy/income/models/bank_notification_model.dart';
import 'package:jabhouy_core/jabhouy_core.dart';
import 'package:jabhouy_sync/jabhouy_sync.dart';

/// Pushes one notification to Firebase.
typedef NotificationUploader = Future<bool> Function(BankNotificationModel);

/// Whether this device is allowed to upload at all.
typedef LocalCaptureGate = Future<bool> Function();

/// Sends income outbox jobs.
///
/// Income is the feature the engine was generalised *from*, so this
/// adapter is the smallest of the five: no create/update/delete split
/// because a notification is only ever uploaded, and no id reconciliation
/// because the fingerprint is the id on both sides.
///
/// What it adds to income is the two things
/// `FirebaseIncomeSyncService` never had. It replayed the entire backlog
/// on every connectivity change, with no attempt count and no delay, so a
/// server that was down got hammered once per network blip. The engine
/// supplies the backoff and the count; this only has to answer "did it
/// land, and is it worth trying again?".
class IncomeSyncAdapter implements FeatureSyncAdapter {
  const IncomeSyncAdapter(this._dao, this._upload, this._canCapture);

  // The DAO rather than the repository: the repository owns the
  // engine, and an adapter the engine calls cannot own the engine
  // back. The other four adapters take their DAO for the same
  // reason.
  final IncomeDao _dao;
  final NotificationUploader _upload;
  final LocalCaptureGate _canCapture;

  @override
  SyncEntityType get entityType => SyncEntityType.bankNotification;

  @override
  Future<SyncPushOutcome> push(OutboxEntry entry) async {
    // entry.localId is the fingerprint: income's idempotency key predates
    // the outbox and is enforced by a UNIQUE constraint on the table.
    final model = await _dao.findByFingerprint(entry.localId);
    if (model == null) {
      // Nothing left to upload. The row was cleared out from under the
      // job, which is not a failure.
      return const SyncPushSucceeded();
    }

    // A device that is not the main device must never upload, and no
    // amount of retrying changes that. Retryable rather than rejected
    // because the role can change: the job waits, backing off, and goes
    // out if this device is promoted.
    if (!await _canCapture()) {
      return const SyncPushRetryable('Not the main device for income sync.');
    }

    final uploaded = await _upload(model);
    await _dao.updateSyncStatus(
      model.fingerprint,
      uploaded ? SyncStatus.synced : SyncStatus.failed,
    );

    if (uploaded) return const SyncPushSucceeded();

    // The Firebase path answers with a bool, so there is no status code to
    // read and nothing distinguishes "the network was down" from "the
    // document was refused". Retryable is the safe reading: the engine's
    // backoff bounds the cost, and dropping a recorded sale is the one
    // outcome worth avoiding.
    return const SyncPushRetryable('Firebase upload did not confirm.');
  }
}
