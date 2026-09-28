import 'package:jabhouy_core/jabhouy_core.dart';

/// Downloads one feature's rows from the server and reconciles them.
///
/// The server cannot say what changed, so an adapter fetches every page
/// and hands the whole list to its DAO. The DAO skips rows with a queued
/// job, and deletes rows the server no longer has only when the list is
/// complete: a partial list must never delete anything.
abstract interface class FeaturePullAdapter {
  SyncEntityType get entityType;

  Future<Result<void>> pullAll();
}
