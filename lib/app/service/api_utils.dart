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
    } catch (e) {
      throw ApiException(
        'Failed to parse response data: $e',
        statusCode: statusCode,
      );
    }
  } else {
    throw ApiException(
      responseBody is Map<String, dynamic> && responseBody['message'] != null
          ? responseBody['message'].toString()
          : 'Error: $statusCode',
      statusCode: statusCode,
    );
  }
}

Future<http.Response> interceptRequest(
  Uri uri,
  Future<http.Response> Function() request, {
  Map<String, dynamic>? body,
}) async {
  final logger = LoggerFactory.createLogger(
    methodCount: 0,
    printTime: false,
  );
  final pathWithQuery = uri.query.isNotEmpty ? '${uri.path}?${uri.query}' : uri.path;
  final startTime = DateTime.now();
  final timeFormatter = DateFormat('MMMM d, yyyy h:mm:ss a');

  logger.d('Request $pathWithQuery started: ${timeFormatter.format(startTime.toLocal())}');

  if (body != null) logger.d('Request body: ${jsonEncode(body)}');

  final response = await request();

  if (response.body.isNotEmpty) {
    logger.d('Response body: ${response.body}');
  }

  final endTime = DateTime.now();

  logger.d('Response $pathWithQuery received: ${response.statusCode} at ${timeFormatter.format(endTime.toLocal())}');

  return response;
}

Map<String, String> getHeaders() {
  return {
    'Content-Type': 'application/json;charset=UTF-8',
    'Connection': 'keep-alive',
  };
}
