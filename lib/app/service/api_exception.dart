part of 'api_service.dart';

class ApiException implements Exception {
  ApiException(
    this.message, {
    this.statusCode,
    StackTrace? stackTrace,
  }) : stackTrace = stackTrace ?? StackTrace.current;

  final String message;
  final int? statusCode;
  final StackTrace stackTrace;

  @override
  String toString() {
    return 'ApiException: $message (Status: $statusCode)\nStackTrace:\n$stackTrace';
  }
}
