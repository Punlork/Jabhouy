part of 'api_service.dart';

ApiResponse<T> handleResponse<T>(
  http.Response response,
  T Function(dynamic) parser,
) {
  final statusCode = response.statusCode;
  final rawBody = response.bodyBytes.isEmpty ? null : response.bodyBytes;

  dynamic responseBody;
  if (rawBody != null) {
    try {
      responseBody = jsonDecode(utf8.decode(rawBody));
    } catch (e) {
      throw ApiException(
        'Failed to parse response: $e',
        statusCode: statusCode,
      );
    }
  }

  if (statusCode >= 200 && statusCode < 300) {
    try {
      return ApiResponse<T>(
        success: true,
        data: responseBody != null ? parser(responseBody) : null,
        message: responseBody is Map<String, dynamic> ? responseBody['message']?.toString() : null,
      );
    } catch (e, stackTrace) {
      throw ApiException(
        'Failed to parse response data: $e',
        statusCode: statusCode,
        stackTrace: stackTrace,
      );
    }
  } else {
    throw ApiException(
      responseBody is Map<String, dynamic> && responseBody['message'] != null
          ? responseBody['message'].toString()
          : 'Error: $statusCode',
      statusCode: statusCode,
      stackTrace: StackTrace.current,
    );
  }
}

Future<http.Response> interceptRequest(
  Uri uri,
  Future<http.Response> Function() request, {
  Map<String, dynamic>? body,
  String? method,
}) async {
  final logger = LoggerFactory.createLogger(
    methodCount: 0,
    printTime: false,
  );
  final pathWithQuery = uri.query.isNotEmpty ? '${uri.path}?${uri.query}' : uri.path;
  final startTime = DateTime.now();

  logger.d('Starting: $method $pathWithQuery');

  if (body != null) logger.d('Request body: ${jsonEncode(body)}');

  final response = await request();

  final endTime = DateTime.now();

  logger.d(
    'Finished: $method $pathWithQuery ${response.statusCode} (${endTime.difference(startTime).inSeconds} sec)',
  );
  return response;
}

Map<String, String> getHeaders() {
  return {
    'Content-Type': 'application/json;charset=UTF-8',
    'Connection': 'keep-alive',
  };
}
