import 'package:my_app/app/app.dart';

abstract class BaseService {
  BaseService(this._apiService);
  final ApiService _apiService;

  String get basePath;

  Future<ApiResponse<T>> get<T>(
    String endpoint, {
    T Function(dynamic)? parser,
    Map<String, dynamic>? queryParameters,
  }) async {
    final response = await _apiService.get(
      '$basePath$endpoint',
      parser: parser,
      queryParameters: queryParameters,
    );
    return ApiResponse<T>(
      success: response.success,
      data: response.data,
      message: response.message,
    );
  }

  Future<ApiResponse<T>> post<T>(
    String endpoint, {
    Map<String, dynamic>? body,
    T Function(dynamic)? parser,
    Map<String, dynamic> Function()? bodyParser,
  }) async {
    final response = await _apiService.post(
      '$basePath$endpoint',
      body: body ?? {},
      parser: parser,
      bodyParser: bodyParser,
    );
    return ApiResponse<T>(
      success: response.success,
      data: response.data,
      message: response.message,
    );
  }

  Future<ApiResponse<T>> put<T>(
    String endpoint, {
    Map<String, dynamic> body = const {},
    T Function(dynamic)? parser,
    Map<String, dynamic> Function()? bodyParser,
  }) async {
    final response = await _apiService.put(
      '$basePath$endpoint',
      body: body,
      parser: parser,
      bodyParser: bodyParser,
    );
    return ApiResponse<T>(
      success: response.success,
      data: response.data,
      message: response.message,
    );
  }

  Future<ApiResponse<T>> delete<T>(
    String endpoint, {
    T Function(dynamic)? parser,
  }) async {
    final response = await _apiService.delete(
      '$basePath$endpoint',
      parser: parser,
    );
    return ApiResponse<T>(
      success: response.success,
      data: response.data,
      message: response.message,
    );
  }
}
