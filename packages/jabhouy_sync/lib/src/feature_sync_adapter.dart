import 'package:jabhouy_core/jabhouy_core.dart';
import 'package:jabhouy_sync/src/transport.dart';

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

/// Turns one failure into the engine's answer.
///
/// The judgement itself lives on [AppException.isRetryable], in
/// `jabhouy_core`, so `jabhouy_sync` and the app agree on it by
/// construction rather than by two copies staying in step.
SyncPushOutcome outcomeFor(AppException error) {
  return error.isRetryable
      ? SyncPushRetryable(error.message)
      : SyncPushRejected(error.message);
}
