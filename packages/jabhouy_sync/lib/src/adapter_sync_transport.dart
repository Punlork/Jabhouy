import 'package:jabhouy_core/jabhouy_core.dart';
import 'package:jabhouy_sync/src/feature_sync_adapter.dart';
import 'package:jabhouy_sync/src/transport.dart';

/// Routes each outbox job to the feature that knows how to send it.
///
/// The only `SyncTransport` the app needs: the engine asks for one, and
/// this hands the job to whichever `FeatureSyncAdapter` claims its entity
/// type. The HTTP itself stays in the adapters, which is what keeps this
/// package pure Dart.
class AdapterSyncTransport implements SyncTransport {
  AdapterSyncTransport(Iterable<FeatureSyncAdapter> adapters)
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
