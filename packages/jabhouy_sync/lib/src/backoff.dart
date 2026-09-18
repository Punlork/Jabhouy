/// How long a failed job waits before the drain loop looks at it again.
///
/// The app had no backoff at all: a push that failed once was marked
/// `syncStatus = 2` and never retried. Doubling with a ceiling keeps a
/// flapping connection from becoming a tight retry loop.
class BackoffPolicy {
  const BackoffPolicy({
    this.base = const Duration(seconds: 5),
    this.max = const Duration(minutes: 30),
  });

  final Duration base;
  final Duration max;

  /// Delay after [attemptCount] failures. The first failure waits [base].
  Duration delayFor(int attemptCount) {
    if (attemptCount <= 0) return base;
    // Shifting past 62 overflows; the cap bites long before that anyway.
    final exponent = attemptCount > 32 ? 32 : attemptCount;
    final scaled = base * (1 << exponent);
    return scaled > max ? max : scaled;
  }
}
