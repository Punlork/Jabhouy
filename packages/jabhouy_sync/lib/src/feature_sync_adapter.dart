import 'package:jabhouy_core/jabhouy_core.dart';
import 'package:jabhouy_sync/src/shop_api.dart';
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

/// [outcomeFor], plus the server's named rules for a Shop-scoped write:
/// 403 and 409 become [SyncPushDropped] instead of a parked rejection.
SyncPushOutcome outcomeForShopWrite(AppException error, String shopId) {
  if (error is ShopApiException && error.code == 'forbidden_role') {
    return SyncPushDropped(SyncDropReason.forbiddenRole, shopId: shopId);
  }
  if (error is ShopApiException && error.code == 'not_member') {
    return SyncPushDropped(SyncDropReason.notMember, shopId: shopId);
  }
  if (error.statusCode == 409) {
    return SyncPushDropped(SyncDropReason.conflict, shopId: shopId);
  }
  return outcomeFor(error);
}
