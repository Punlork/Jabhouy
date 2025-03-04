part of 'api_service.dart';

class ApiResponse<T> {
  ApiResponse({
    required this.success,
    this.data,
    this.message,
  });
  final bool success;
  final T? data;
  final String? message;
}
