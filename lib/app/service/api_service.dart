// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:my_app/app/app.dart';

import 'package:shared_preferences/shared_preferences.dart';

part 'api_exception.dart';
part 'api_response.dart';
part 'api_utils.dart';
part 'api_cookies.dart';

class ApiService {
  factory ApiService() => _instance;

  ApiService._internal() : _client = http.Client() {
    _baseUrl = dotenv.get('BASE_URL', fallback: '');
    assert(_baseUrl.isNotEmpty, 'BASE_URL env must be provided');
  }

  final cookies = ApiCookies();
  static final _instance = ApiService._internal();

  String _baseUrl = '';
  static const _timeout = Duration(seconds: 30);
  final http.Client _client;

  Future<ApiResponse<T>> get<T>(
    String endpoint, {
    Map<String, String>? headers,
    T Function(dynamic)? parser,
    BuildContext? context,
    Map<String, dynamic>? queryParameters,
    bool showSnackBar = true,
  }) async {
    try {
      var tempHeaders = getHeaders();
      final uri = Uri.https(
        _baseUrl,
        endpoint,
        queryParameters,
      );

      final cookieHeader = cookies.getCookieHeader(uri);
      if (cookieHeader != null) tempHeaders['Cookie'] = cookieHeader;
      if (headers != null) tempHeaders = {...tempHeaders, ...headers};

      final response = await interceptRequest(
        uri,
        () => _client.get(uri, headers: tempHeaders).timeout(_timeout),
      );

      cookies.updateCookies(uri, response);
      return handleResponse(response, parser ?? (data) => data as T);
    } catch (e, stackTrace) {
      logger.e(
        'Error occurred in GET request to $endpoint',
        error: e,
        stackTrace: stackTrace,
      );
      final errorMessage = e is ApiException ? e.message : 'Network error: $e';
      if (showSnackBar) showErrorSnackBar(context, errorMessage);
      return ApiResponse<T>(success: false, message: errorMessage);
    } finally {
      LoadingOverlay.hide();
    }
  }

  Future<ApiResponse<T>> post<T>(
    String endpoint, {
    Map<String, dynamic> body = const {},
    Map<String, dynamic> Function()? bodyParser,
    Map<String, String>? headers,
    T Function(dynamic)? parser,
    BuildContext? context,
    bool showSnackBar = true,
    File? imageFile,
    String imageFieldName = 'image',
  }) async {
    try {
      var tempHeaders = getHeaders();
      final uri = Uri.https(_baseUrl, endpoint);
      final cookieHeader = cookies.getCookieHeader(uri);
      if (cookieHeader != null) tempHeaders['Cookie'] = cookieHeader;
      if (headers != null) tempHeaders = {...tempHeaders, ...headers};

      http.Response response;

      if (imageFile != null) {
        final request = http.MultipartRequest('POST', uri)
          ..headers.addAll(tempHeaders)
          ..files.add(
            await http.MultipartFile.fromPath(
              'image',
              imageFile.path,
              filename: imageFieldName,
            ),
          );

        if (body.isNotEmpty) {
          request.fields.addAll(
            body.map((key, value) => MapEntry(key, value.toString())),
          );
        } else if (bodyParser != null) {
          request.fields.addAll(
            bodyParser().map(
              (key, value) => MapEntry(
                key,
                value.toString(),
              ),
            ),
          );
        }

        response = await interceptRequest(
          uri,
          () async {
            final streamedResponse = await request.send().timeout(_timeout);
            return http.Response.fromStream(streamedResponse);
          },
        );
      } else {
        final tempBody = <String, dynamic>{};
        if (body.isNotEmpty) {
          tempBody.addAll(body);
        } else if (bodyParser != null) {
          tempBody.addAll(bodyParser());
        }
        final encodeBody = json.encode(tempBody);

        response = await interceptRequest(
          uri,
          () => _client.post(uri, headers: tempHeaders, body: encodeBody).timeout(_timeout),
        );
      }

      cookies.updateCookies(uri, response);
      return handleResponse(response, parser ?? (data) => data as T);
    } catch (e, stackTrace) {
      final errorMessage = e is ApiException ? e.message : 'Network error: $e';
      logger.e(
        'Error occurred in POST request to $endpoint',
        error: e,
        stackTrace: stackTrace,
      );
      if (showSnackBar) showErrorSnackBar(context, errorMessage);
      return ApiResponse<T>(success: false, message: errorMessage);
    } finally {
      LoadingOverlay.hide();
    }
  }

  Future<ApiResponse<T>> put<T>(
    String endpoint, {
    Map<String, dynamic> body = const {},
    Map<String, dynamic> Function()? bodyParser,
    Map<String, String>? headers,
    T Function(dynamic)? parser,
    BuildContext? context,
    bool showSnackBar = true,
  }) async {
    try {
      final tempBody = <String, dynamic>{};

      if (body.isNotEmpty) {
        tempBody.addAll(body);
      } else if (bodyParser != null) {
        tempBody.addAll(bodyParser());
      }

      final encodeBody = json.encode(tempBody);
      var tempHeaders = getHeaders();
      final uri = Uri.https(_baseUrl, endpoint);
      final cookieHeader = cookies.getCookieHeader(uri);
      if (cookieHeader != null) tempHeaders['Cookie'] = cookieHeader;
      if (headers != null) tempHeaders = {...tempHeaders, ...headers};

      final response = await interceptRequest(
        uri,
        () => _client
            .put(
              uri,
              headers: tempHeaders,
              body: encodeBody,
            )
            .timeout(_timeout),
      );

      cookies.updateCookies(uri, response);
      return handleResponse(response, parser ?? (data) => data as T);
    } catch (e, stackTrace) {
      final errorMessage = e is ApiException ? e.message : 'Network error: $e';
      logger.e(
        'Error occurred in PUT request to $endpoint',
        error: e,
        stackTrace: stackTrace,
      );
      if (showSnackBar) showErrorSnackBar(context, errorMessage);
      return ApiResponse<T>(success: false, message: errorMessage);
    } finally {
      LoadingOverlay.hide();
    }
  }

  Future<ApiResponse<T>> delete<T>(
    String endpoint, {
    Map<String, String>? headers,
    T Function(dynamic)? parser,
    BuildContext? context,
    bool showSnackBar = true,
  }) async {
    try {
      var tempHeaders = getHeaders();
      final uri = Uri.https(_baseUrl, endpoint);
      final cookieHeader = cookies.getCookieHeader(uri);
      if (cookieHeader != null) tempHeaders['Cookie'] = cookieHeader;
      if (headers != null) tempHeaders = {...tempHeaders, ...headers};

      final response = await interceptRequest(
        uri,
        () => _client.delete(uri, headers: tempHeaders).timeout(_timeout),
      );

      cookies.updateCookies(uri, response);
      return handleResponse(response, parser ?? (data) => data as T);
    } catch (e, stackTrace) {
      final errorMessage = e is ApiException ? e.message : 'Network error: $e';
      logger.e(
        'Error occurred in DELETE request to $endpoint',
        error: e,
        stackTrace: stackTrace,
      );
      if (showSnackBar) showErrorSnackBar(context, errorMessage);
      return ApiResponse<T>(success: false, message: errorMessage);
    } finally {
      LoadingOverlay.hide();
    }
  }
}
