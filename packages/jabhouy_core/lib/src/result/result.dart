import 'package:jabhouy_core/src/result/app_exception.dart';

/// The outcome of something that can fail.
///
/// Replaces `ApiResponse{success: bool, data: T?}`, where a caller that
/// wanted the value had to check `success` and then write `data!` —
/// two steps the compiler could not connect, so the `!` was load-bearing
/// and unchecked. Here the value only exists inside [Ok], so there is
/// nothing to force.
sealed class Result<T> {
  const Result();

  /// Wraps a call that throws. Anything other than an [AppException]
  /// becomes one, so a caller never has to catch two shapes.
  static Future<Result<T>> guard<T>(Future<T> Function() body) async {
    try {
      return Ok(await body());
    } on AppException catch (error, stackTrace) {
      return Err(
        AppException(
          error.message,
          statusCode: error.statusCode,
          cause: error.cause,
          stackTrace: error.stackTrace ?? stackTrace,
        ),
      );
    } catch (error, stackTrace) {
      return Err(
        AppException('$error', cause: error, stackTrace: stackTrace),
      );
    }
  }

  bool get isOk => this is Ok<T>;

  T? get valueOrNull => switch (this) {
        Ok(:final value) => value,
        Err() => null,
      };

  AppException? get errorOrNull => switch (this) {
        Ok() => null,
        Err(:final error) => error,
      };

  /// Collapses both branches to one value. The reason [valueOrNull] is
  /// rarely the right call: this one cannot forget the failure.
  R fold<R>({
    required R Function(T value) ok,
    required R Function(AppException error) err,
  }) =>
      switch (this) {
        Ok(:final value) => ok(value),
        Err(:final error) => err(error),
      };

  /// Transforms the value, leaving a failure untouched.
  Result<R> map<R>(R Function(T value) transform) => switch (this) {
        Ok(:final value) => Ok(transform(value)),
        Err(:final error) => Err(error),
      };
}

final class Ok<T> extends Result<T> {
  const Ok(this.value);

  final T value;
}

final class Err<T> extends Result<T> {
  const Err(this.error);

  final AppException error;
}
