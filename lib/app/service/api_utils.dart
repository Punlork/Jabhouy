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
  Map<String, String>? headers,
  String? requestBody,
  String? method,
}) async {
  final logger = LoggerFactory.createLogger(
    methodCount: 0,
    printTime: false,
  );
  final inspector = NetworkInspectorService.instance;
  final pathWithQuery = uri.query.isNotEmpty ? '${uri.path}?${uri.query}' : uri.path;
  final startTime = DateTime.now();
  final normalizedMethod = method ?? 'REQUEST';

  String? formattedBody;
  if (requestBody != null) {
    try {
      final decoded = jsonDecode(requestBody);
      formattedBody = const JsonEncoder.withIndent('  ').convert(decoded);
    } catch (_) {
      formattedBody = requestBody; // fallback to raw if not JSON
    }
  }

  logger.d(
    'Starting: $normalizedMethod $pathWithQuery'
    '${formattedBody != null ? ' | Request body:\n$formattedBody' : ''}',
  );

  try {
    final response = await request();
    final endTime = DateTime.now();

    String? formattedResponseBody;

    if (response.bodyBytes.isNotEmpty) {
      try {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes, allowMalformed: true));
        formattedResponseBody = const JsonEncoder.withIndent('  ').convert(decoded);
      } catch (_) {
        formattedResponseBody = utf8.decode(response.bodyBytes, allowMalformed: true);
      }
    }

    logger.d(
      'Finished: $normalizedMethod $pathWithQuery ${response.statusCode} (${endTime.difference(startTime).inSeconds} sec)'
      '${formattedResponseBody != null ? ' | Response body:\n$formattedResponseBody' : ''}',
    );

    inspector.capture(
      timestamp: startTime,
      method: normalizedMethod,
      uri: uri,
      duration: endTime.difference(startTime),
      requestHeaders: headers ?? const {},
      requestBody: requestBody,
      statusCode: response.statusCode,
      responseHeaders: response.headers,
      responseBody: response.bodyBytes.isEmpty ? null : utf8.decode(response.bodyBytes, allowMalformed: true),
    );
    return response;
  } catch (error, stackTrace) {
    final endTime = DateTime.now();
    logger.e(
      'Failed: $normalizedMethod $pathWithQuery',
      error: error,
      stackTrace: stackTrace,
    );
    inspector.capture(
      timestamp: startTime,
      method: normalizedMethod,
      uri: uri,
      duration: endTime.difference(startTime),
      requestHeaders: headers ?? const {},
      requestBody: requestBody,
      error: '$error\n$stackTrace',
    );
    rethrow;
  }
}

Map<String, String> getHeaders() {
  return {
    'Content-Type': 'application/json;charset=UTF-8',
    'Connection': 'keep-alive',
  };
}
