import 'package:jabhouy/app/app.dart';
import 'package:jabhouy/shop/shop.dart';
import 'package:jabhouy_core/jabhouy_core.dart';
import 'package:jabhouy_sync/jabhouy_sync.dart';

/// Sends shop outbox jobs, and applies whatever the server answers to the
/// local row.
///
/// The engine owns the queue — when to try, how long to wait, when to stop.
/// This owns the one thing the engine cannot know: that a `shopItem`
/// create is `POST /items` and that its response carries the id the local
/// negative id must be swapped for.
class ShopSyncAdapter implements FeatureSyncAdapter {
  const ShopSyncAdapter(this._dao, this._api);

  final ShopDao _dao;
  final ShopApi _api;

  @override
  SyncEntityType get entityType => SyncEntityType.shopItem;

  @override
  Future<SyncPushOutcome> push(OutboxEntry entry) async {
    final id = int.tryParse(entry.localId);
    if (id == null) {
      return SyncPushRejected('Unparseable shop item id "${entry.localId}"');
    }

    return switch (entry.operation) {
      SyncOperation.delete => _pushDelete(id),
      SyncOperation.create => _pushCreate(id),
      SyncOperation.update => _pushUpdate(id),
    };
  }

  Future<SyncPushOutcome> _pushDelete(int id) async {
    // A row the server never saw needs no DELETE; it only has to stop
    // existing here.
    if (id < 0) {
      await _dao.purge(id);
      return const SyncPushSucceeded();
    }

    final response = await _api.deleteItem(id);

    // A 404 means the row is already gone server-side, which is the state
    // this job was trying to reach.
    if (response.success || response.statusCode == 404) {
      await _dao.purge(id);
      return const SyncPushSucceeded();
    }

    return _fail(id, response.statusCode, response.message);
  }

  Future<SyncPushOutcome> _pushCreate(int id) async {
    final item = await _dao.findById(id);
    // The user deleted it before this job ran. Nothing to create, and the
    // delete job behind this one will do the rest.
    if (item == null) return const SyncPushSucceeded();

    final response = await _api.createItem(item);
    final created = response.data;
    if (response.success && created != null) {
      await _dao.reconcileCreated(localId: id, serverItem: created);
      return SyncPushSucceeded(serverId: '${created.id}');
    }

    return _fail(id, response.statusCode, response.message);
  }

  Future<SyncPushOutcome> _pushUpdate(int id) async {
    final item = await _dao.findById(id);
    if (item == null) return const SyncPushSucceeded();

    final response = await _api.updateItem(item);
    final updated = response.data;
    if (response.success && updated != null) {
      await _dao.replace(updated, SyncStatus.synced);
      return const SyncPushSucceeded();
    }

    return _fail(id, response.statusCode, response.message);
  }

  /// A row stays `pending` while the engine still intends to retry it, and
  /// only becomes `failed` once the server has said no on the merits. The
  /// old code wrote `failed` on the first hiccup and never looked again.
  Future<SyncPushOutcome> _fail(int id, int? statusCode, String? message) async {
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
