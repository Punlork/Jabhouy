/// Why an operation failed, in a form both the UI and the sync engine can
/// act on.
///
/// Replaces `ApiException`, which lived in the app package and so could
/// not be named by `jabhouy_sync`, and the twelve `catch (_)` blocks that
/// discarded the reason entirely.
class AppException implements Exception {
  const AppException(
    this.message, {
    this.statusCode,
    this.cause,
    this.stackTrace,
  });

  /// The request never got an answer: a timeout, a dropped connection,
  /// DNS. [statusCode] stays null, which is what makes it retryable.
  const AppException.network(String message, {Object? cause})
      : this(message, cause: cause);

  final String message;

  /// The HTTP status, when the server gave one.
  final int? statusCode;

  /// The error this wraps, kept so a log can say more than [message].
  final Object? cause;

  final StackTrace? stackTrace;

  /// Whether sending the same bytes again could plausibly work.
  ///
  /// This is the judgement the old code could not make: every failure
  /// became `syncStatus = 2` and stopped. No status at all means the
  /// request never landed. 5xx is the server's problem, not the payload's.
  /// 408 and 429 are the two 4xx that explicitly ask for a repeat.
  bool get isRetryable {
    final code = statusCode;
    if (code == null) return true;
    return code >= 500 || code == 408 || code == 429;
  }

  @override
  String toString() => statusCode == null
      ? 'AppException: $message'
      : 'AppException($statusCode): $message';
}
