import 'package:jabhouy_core/jabhouy_core.dart';
import 'package:jabhouy_sync/jabhouy_sync.dart';

/// Pushes the outbox jobs belonging to one feature.
///
/// The engine is generic over entities on purpose; knowing that a
/// `shopItem` job becomes `POST /items` is feature knowledge, and it lives
/// with the feature. Phase 4 adds a sibling per slice rather than growing
/// a switch in one file.
abstract interface class FeatureSyncAdapter {
  SyncEntityType get entityType;

  Future<SyncPushOutcome> push(OutboxEntry entry);
}

/// Turns one HTTP result into the engine's three-way answer.
///
/// The distinction only became possible once `ApiResponse` kept the status
/// code `ApiException` had always carried: before this, every failure was
/// indistinguishable and the old code marked them all `syncStatus = 2`.
SyncPushOutcome outcomeFor({
  required bool success,
  required int? statusCode,
  String? message,
}) {
  if (success) return const SyncPushSucceeded();

  final error = message ?? 'HTTP ${statusCode ?? 'error'}';

  // No status at all means the request never got an answer: a timeout, a
  // dropped connection, DNS. Always worth another go.
  if (statusCode == null) return SyncPushRetryable(error);

  // 408 and 429 are the two 4xx the server is explicitly asking us to
  // repeat.
  if (statusCode >= 500 || statusCode == 408 || statusCode == 429) {
    return SyncPushRetryable(error);
  }

  return SyncPushRejected(error);
}
