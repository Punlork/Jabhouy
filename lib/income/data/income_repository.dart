import 'package:jabhouy/income/models/bank_notification_model.dart';
import 'package:jabhouy_core/jabhouy_core.dart';

/// The seam the income bloc and its use cases talk to.
///
/// Imports no Flutter, so `logic/` may depend on it.
abstract class IncomeRepository {
  Stream<List<BankNotificationModel>> watchNotifications({
    String searchQuery,
    DateTime? fromDate,
    DateTime? toDate,
    BankApp? bankFilter,
    NotificationRecordFilter recordFilter,
  });

  Future<BankNotificationModel?> findByFingerprint(String fingerprint);

  /// Everything the server has not acknowledged, `failed` rows included.
  Future<List<BankNotificationModel>> pendingNotifications();

  /// Pulls the server's list. Caching is [store]'s job, not this one's.
  Future<Result<List<BankNotificationModel>>> fetchRemote();

  /// Returns true when the notification was new to this device.
  Future<bool> store(
    BankNotificationModel model, {
    String? rawPayloadOverride,
  });

  Future<void> updateSyncStatus(String fingerprint, SyncStatus status);

  /// Re-parses rows stored before the parser could read their bank or
  /// amount, and returns how many it repaired.
  Future<int> backfillMetadata();

  /// Queues a notification for upload. The engine decides when.
  Future<void> enqueueUpload(BankNotificationModel model);

  /// Pushes whatever is queued now.
  Future<void> drainUploads();
}
