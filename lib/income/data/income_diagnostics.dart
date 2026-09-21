/// Somewhere to record what the income paths did.
///
/// A port, not the service: `NotificationDiagnosticsService` reaches the
/// Android bridge through the income barrel and so carries Flutter, which
/// `logic/` may not. The service satisfies this interface as it stands —
/// the seam costs one `implements`.
///
/// It replaces nothing yet; it exists so a use case can log without
/// importing the platform.
// A port, not a helper: one seam, one thing to fake. A top-level
// function would remove the seam this file exists to create.
// ignore: one_member_abstracts
abstract interface class IncomeDiagnostics {
  Future<void> log({
    required String source,
    required String message,
    String level,
    Map<String, dynamic>? metadata,
  });
}
