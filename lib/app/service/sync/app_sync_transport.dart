import 'package:jabhouy_core/jabhouy_core.dart';
import 'package:jabhouy_sync/jabhouy_sync.dart';

/// Routes each outbox job to the feature that knows how to send it.
///
/// This is the app's implementation of the `SyncTransport` port. The engine
/// stays pure Dart because everything HTTP lives on this side of the seam.
class AppSyncTransport implements SyncTransport {
  AppSyncTransport(Iterable<FeatureSyncAdapter> adapters)
      : _adapters = {for (final a in adapters) a.entityType: a};

  final Map<SyncEntityType, FeatureSyncAdapter> _adapters;

  @override
  Future<SyncPushOutcome> push(OutboxEntry entry) {
    final adapter = _adapters[entry.entityType];
    if (adapter == null) {
      // Rejected rather than retryable: no amount of waiting registers an
      // adapter, and the job keeps its reason instead of spinning.
      return Future.value(
        SyncPushRejected('No sync adapter for ${entry.entityType.name}'),
      );
    }
    return adapter.push(entry);
  }
}
