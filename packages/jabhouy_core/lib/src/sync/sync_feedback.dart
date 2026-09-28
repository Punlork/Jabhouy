import 'package:jabhouy_core/src/sync/sync_status.dart';

/// The message a local-first write deserves, given where the row ended up.
///
/// The repositories stopped returning a message when they moved to
/// `Result`: it carries a value or a reason, and choosing words is the
/// `ui` layer's job. This is that choice, in one place so the four
/// features word it the same way — and it is now driven by what actually
/// happened rather than by a connectivity check taken before the attempt.
///
/// With [inBackground], a save returns before its push, so the row is always
/// pending here and says nothing about the server; the sync indicator
/// carries that instead, and the message is just [done].
String syncFeedback(
  SyncStatus status, {
  required String done,
  bool inBackground = false,
}) {
  if (inBackground) return done;
  return switch (status) {
    SyncStatus.synced => done,
    SyncStatus.pending =>
      'Saved offline. It will sync when you are back online.',
    SyncStatus.failed => 'Saved on this device. The server rejected it.',
  };
}
