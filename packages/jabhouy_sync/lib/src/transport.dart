import 'package:jabhouy_core/jabhouy_core.dart';

/// What happened when the engine pushed one job.
///
/// The three cases exist because the old code had one: every failure became
/// `syncStatus = 2` and stopped there. Separating "try again" from "never
/// going to work" is what makes a retry loop safe to run.
sealed class SyncPushOutcome {
  const SyncPushOutcome();
}

/// The server accepted the job.
final class SyncPushSucceeded extends SyncPushOutcome {
  const SyncPushSucceeded({this.serverId});

  /// The id the server assigned, when it minted one.
  final String? serverId;
}

/// The push failed in a way that may succeed later: a timeout, a 500, no
/// connectivity. The job stays queued and its backoff advances.
final class SyncPushRetryable extends SyncPushOutcome {
  const SyncPushRetryable(this.error);

  final String error;
}

/// The server rejected the job on its merits: a 400, a validation failure.
/// Retrying sends the same bytes and gets the same answer, so the job stops
/// and keeps its error for a human to read.
final class SyncPushRejected extends SyncPushOutcome {
  const SyncPushRejected(this.error);

  final String error;
}

/// Why the server refused a job in a way a new pull settles.
enum SyncDropReason {
  /// 403 `forbidden_role`: the Member's role no longer allows the write.
  forbiddenRole,

  /// 403 `not_member`: the Member was removed from the Shop.
  notMember,

  /// 409: the server's row and the job disagree; its row wins.
  conflict,
}

/// The server refused the job and a retry cannot help (decision 11): the
/// engine drops it and pulls the Shop again so the phone shows what the
/// server holds. Never retried.
final class SyncPushDropped extends SyncPushOutcome {
  const SyncPushDropped(this.reason, {required this.shopId});

  final SyncDropReason reason;
  final String shopId;
}

/// Sends one job to the server.
///
/// This is the only part of syncing that needs a network client, which is
/// why it is a port: the app implements it over HTTP, tests implement it
/// with a list. Keeping it abstract is what lets this package build and
/// test without Flutter.
// A port, not a helper: one seam, one thing to fake. A top-level
// function would remove the seam this package exists to keep.
// ignore: one_member_abstracts
abstract interface class SyncTransport {
  Future<SyncPushOutcome> push(OutboxEntry entry);
}

/// Records what the engine did, so a dropped write leaves a trail.
///
/// Replaces the `catch (_)` blocks that discarded the reason for failure.
// ignore: one_member_abstracts — see SyncTransport.
abstract interface class SyncDiagnostics {
  void log(String message, {Map<String, Object?> data});
}

/// Discards entries. The default when a host supplies nothing.
final class NoopSyncDiagnostics implements SyncDiagnostics {
  const NoopSyncDiagnostics();

  @override
  void log(String message, {Map<String, Object?> data = const {}}) {}
}
