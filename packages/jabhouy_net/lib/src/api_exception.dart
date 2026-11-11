part of 'api_service.dart';

class ApiException implements Exception {
  ApiException(
    this.message, {
    this.statusCode,
    this.code,
    StackTrace? stackTrace,
  }) : stackTrace = stackTrace ?? StackTrace.current;

  final String message;
  final int? statusCode;

  /// The API's machine-readable error (`{ code, message }`), e.g. `not_member`.
  final String? code;
  final StackTrace stackTrace;

  @override
  String toString() => 'ApiException: $message (Status: $statusCode) ';
} 
