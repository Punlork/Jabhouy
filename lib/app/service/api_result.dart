import 'package:jabhouy/app/app.dart';
import 'package:jabhouy_core/jabhouy_core.dart';

/// The one place `ApiResponse` becomes a [Result].
///
/// `ApiResponse` stays as `ApiService`'s return type for now — auth,
/// profile, upload, fcm and income still speak it. The layered features
/// convert at the edge of their `api/` class, so nothing above the `data/`
/// layer has to know the older shape exists.
extension ApiResponseToResult<T extends Object> on ApiResponse<T> {
  /// For calls whose success carries a value. A success with no body is a
  /// failure here, because the caller asked for something.
  Result<T> toResult({String ifMissing = 'The server returned no data.'}) {
    final value = data;
    if (success && value != null) return Ok(value);
    return Err(
      AppException(
        success ? ifMissing : (message ?? 'Request failed.'),
        statusCode: statusCode,
      ),
    );
  }
}

/// For calls whose success carries nothing, such as a delete.
extension ApiResponseToVoidResult on ApiResponse<dynamic> {
  Result<void> toVoidResult() {
    if (success) return const Ok<void>(null);
    return Err(
      AppException(
        message ?? 'Request failed.',
        statusCode: statusCode,
      ),
    );
  }
}
