import 'package:jabhouy_core/jabhouy_core.dart';

/// The message a local-first write deserves, given where the row ended up.
///
/// The repositories stopped returning a message when they moved to
/// `Result`: it carries a value or a reason, and choosing words is the
/// `ui` layer's job. This is that choice, in one place so the four
/// features word it the same way — and it is now driven by what actually
/// happened rather than by a connectivity check taken before the attempt.
String syncFeedback(SyncStatus status, {required String done}) {
  return switch (status) {
    SyncStatus.synced => done,
    SyncStatus.pending =>
      'Saved offline. It will sync when you are back online.',
    SyncStatus.failed => 'Saved on this device. The server rejected it.',
  };
}
