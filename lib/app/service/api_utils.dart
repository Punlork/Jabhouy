part of 'api_service.dart';

ApiResponse<T> handleResponse<T>(
  http.Response response,
  T Function(dynamic) parser,
) {
  final statusCode = response.statusCode;
  final rawBody = response.body.isEmpty || response.body == 'null' ? null : response.body;

  dynamic responseBody;
  if (rawBody != null) {
    try {
      responseBody = jsonDecode(rawBody);
      if (responseBody is! Map<String, dynamic> && responseBody != null) {
        throw const FormatException('Response body is not a valid JSON object');
      }
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
        data: parser(responseBody),
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

Future<http.Response> interceptRequest(Future<http.Response> Function() request) async {
  developer.log('Request started: ${DateTime.now()}');
  final response = await request();
  developer.log('Response received: ${response.statusCode} at ${DateTime.now()}');
  return response;
}

Map<String, String> getHeaders() {
  return {
    'Content-Type': 'application/json;charset=UTF-8',
    'Connection': 'keep-alive',
  };
}
