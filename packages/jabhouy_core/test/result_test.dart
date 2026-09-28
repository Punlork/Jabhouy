// Runs under `dart test`: Result and AppException must be usable from
// jabhouy_sync, which has no Flutter.
import 'package:jabhouy_core/jabhouy_core.dart';
import 'package:test/test.dart';

void main() {
  group('Result', () {
    test('an Ok carries its value where the compiler can see it', () {
      const Result<int> result = Ok(42);

      // The point of the type: no `!`, no success flag to check first.
      final doubled = result.fold(ok: (v) => v * 2, err: (_) => -1);
      expect(doubled, 84);
      expect(result.isOk, isTrue);
      expect(result.errorOrNull, isNull);
    });

    test('an Err carries a reason instead of a null', () {
      const Result<int> result = Err(AppException('nope', statusCode: 400));

      expect(result.isOk, isFalse);
      expect(result.valueOrNull, isNull);
      expect(result.errorOrNull?.message, 'nope');
      expect(result.fold(ok: (_) => 'ok', err: (e) => e.message), 'nope');
    });

    test('map leaves a failure alone', () {
      const Result<int> ok = Ok(2);
      const Result<int> err = Err(AppException('nope'));

      expect(ok.map((v) => v + 1).valueOrNull, 3);
      expect(err.map((v) => v + 1).errorOrNull?.message, 'nope');
    });

    test('guard turns a thrown AppException into an Err, keeping its code',
        () async {
      final result = await Result.guard<int>(
        () async => throw const AppException('bad request', statusCode: 400),
      );

      expect(result.errorOrNull?.statusCode, 400);
      expect(result.errorOrNull?.message, 'bad request');
    });

    test('guard wraps anything else rather than letting it escape',
        () async {
      final result = await Result.guard<int>(
        () async => throw StateError('boom'),
      );

      expect(result.errorOrNull, isNotNull);
      expect(result.errorOrNull?.cause, isA<StateError>());
      expect(
        result.errorOrNull?.statusCode,
        isNull,
        reason: 'no HTTP answer, so retryable',
      );
    });

    test('guard returns Ok when nothing throws', () async {
      final result = await Result.guard<int>(() async => 7);
      expect(result.valueOrNull, 7);
    });
  });

  group('AppException.isRetryable', () {
    test('no status means the request never landed', () {
      expect(const AppException('timeout').isRetryable, isTrue);
      expect(const AppException.network('dns').isRetryable, isTrue);
    });

    test("5xx is the server's problem, not the payload's", () {
      for (final code in [500, 502, 503, 504]) {
        expect(
          AppException('x', statusCode: code).isRetryable,
          isTrue,
          reason: '$code',
        );
      }
    });

    test('408 and 429 are the 4xx that ask for a repeat', () {
      expect(const AppException('x', statusCode: 408).isRetryable, isTrue);
      expect(const AppException('x', statusCode: 429).isRetryable, isTrue);
    });

    test('other 4xx will answer the same way every time', () {
      for (final code in [400, 401, 403, 404, 422]) {
        expect(
          AppException('x', statusCode: code).isRetryable,
          isFalse,
          reason: '$code',
        );
      }
    });
  });
}
