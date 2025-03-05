// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'dart:developer' as developer;

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
    bool showSnackBar = true,
  }) async {
    try {
      var tempHeaders = getHeaders();
      final uri = Uri.https(_baseUrl, endpoint);
      final cookieHeader = cookies.getCookieHeader(uri);
      if (cookieHeader != null) tempHeaders['Cookie'] = cookieHeader;
      if (headers != null) tempHeaders = {...tempHeaders, ...headers};

      final response = await interceptRequest(
        () => _client
            .get(
              uri,
              headers: tempHeaders,
            )
            .timeout(_timeout),
      );

      cookies.updateCookies(uri, response);
      final apiResponse = handleResponse(response, parser ?? (data) => data as T);
      return apiResponse;
    } catch (e, stackTrace) {
      final errorMessage = e is ApiException ? e.message : 'Network error: $e';
      developer.log(
        'Error occurred in GET request to $endpoint',
        error: e,
        stackTrace: stackTrace,
        level: 1000,
      );
      if (showSnackBar) {
        showErrorSnackBar(context, errorMessage);
      }
      return ApiResponse<T>(success: false, message: errorMessage);
    }
  }

  Future<ApiResponse<T>> post<T>(
    String endpoint, {
    Map<String, dynamic> body = const {},
    Map<String, String>? headers,
    T Function(dynamic)? parser,
    BuildContext? context,
    bool showSnackBar = true,
  }) async {
    try {
      final encodeBody = json.encode(body);
      var tempHeaders = getHeaders();
      final uri = Uri.https(_baseUrl, endpoint);
      final cookieHeader = cookies.getCookieHeader(uri);
      if (cookieHeader != null) tempHeaders['Cookie'] = cookieHeader;
      if (headers != null) tempHeaders = {...tempHeaders, ...headers};

      final response = await interceptRequest(
        () => _client
            .post(
              uri,
              headers: tempHeaders,
              body: encodeBody,
            )
            .timeout(_timeout),
      );

      cookies.updateCookies(uri, response);
      final res = handleResponse(response, parser ?? (data) => data as T);
      return res;
    } catch (e, stackTrace) {
      final errorMessage = e is ApiException ? e.message : 'Network error: $e';
      developer.log(
        'Error occurred in POST request to $endpoint',
        error: e,
        stackTrace: stackTrace,
        level: 1000,
      );
      if (showSnackBar) {
        showErrorSnackBar(context, errorMessage);
      }
      return ApiResponse<T>(success: false, message: errorMessage);
    } finally {
      LoadingOverlay.hide();
    }
  }

  Future<ApiResponse<T>> put<T>(
    String endpoint, {
    required Map<String, dynamic> body,
    Map<String, String>? headers,
    T Function(dynamic)? parser,
    BuildContext? context,
    bool showSnackBar = true,
  }) async {
    try {
      final encodeBody = json.encode(body);
      var tempHeaders = getHeaders();
      final uri = Uri.https(_baseUrl, endpoint);
      final cookieHeader = cookies.getCookieHeader(uri);
      if (cookieHeader != null) tempHeaders['Cookie'] = cookieHeader;
      if (headers != null) tempHeaders = {...tempHeaders, ...headers};

      final response = await interceptRequest(
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
      developer.log(
        'Error occurred in PUT request to $endpoint',
        error: e,
        stackTrace: stackTrace,
        level: 1000,
      );
      if (showSnackBar) {
        showErrorSnackBar(context, errorMessage);
      }
      return ApiResponse<T>(success: false, message: errorMessage);
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
        () => _client
            .delete(
              uri,
              headers: tempHeaders,
            )
            .timeout(_timeout),
      );

      cookies.updateCookies(uri, response);
      return handleResponse(response, parser ?? (data) => data as T);
    } catch (e, stackTrace) {
      final errorMessage = e is ApiException ? e.message : 'Network error: $e';
      developer.log(
        'Error occurred in DELETE request to $endpoint',
        error: e,
        stackTrace: stackTrace,
        level: 1000,
      );
      if (showSnackBar) {
        showErrorSnackBar(context, errorMessage);
      }
      return ApiResponse<T>(success: false, message: errorMessage);
    }
  }
}
