part of 'api_service.dart';

class ApiResponse<T> {
  ApiResponse({
    required this.success,
    this.data,
    this.message,
    this.statusCode,
    this.code,
  });
  final bool success;
  final T? data;
  final String? message;

  /// The HTTP status, when there was one.
  ///
  /// `ApiException` has always carried this and `ApiService` has always
  /// thrown it away, which left every caller unable to tell a 500 from a
  /// 400. The sync engine is the first caller that must: one is worth
  /// retrying and the other never will be.
  final int? statusCode;

  /// The API's error code on a failure (`invite_used`, `not_member`, …):
  /// what a caller matches on, since [message] is for people.
  final String? code;
}
