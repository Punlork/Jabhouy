import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

class NetworkLogEntry {
  const NetworkLogEntry({
    required this.timestamp,
    required this.method,
    required this.uri,
    required this.duration,
    required this.requestHeaders,
    this.requestBody,
    this.statusCode,
    this.responseHeaders = const {},
    this.responseBody,
    this.error,
  });

  final DateTime timestamp;
  final String method;
  final Uri uri;
  final Duration duration;
  final Map<String, String> requestHeaders;
  final String? requestBody;
  final int? statusCode;
  final Map<String, String> responseHeaders;
  final String? responseBody;
  final String? error;

  bool get isSuccess => error == null;
}

class NetworkInspectorService {
  NetworkInspectorService._internal();

  static final NetworkInspectorService instance =
      NetworkInspectorService._internal();
  static const _maxEntries = 150;
  static const _maxBodyLength = 4000;
  static const _redactedValue = '***';
  static const _redactedHeaders = {'authorization', 'cookie', 'set-cookie'};

  final _entries = <NetworkLogEntry>[];
  final _entriesController =
      StreamController<List<NetworkLogEntry>>.broadcast();

  bool captureEnabled = !kReleaseMode;
  List<NetworkLogEntry> get entries => List.unmodifiable(_entries);
  Stream<List<NetworkLogEntry>> get entriesStream => _entriesController.stream;

  void clear() {
    _entries.clear();
    _entriesController.add(List.unmodifiable(_entries));
  }

  void capture({
    required DateTime timestamp,
    required String method,
    required Uri uri,
    required Duration duration,
    Map<String, String> requestHeaders = const {},
    String? requestBody,
    int? statusCode,
    Map<String, String> responseHeaders = const {},
    String? responseBody,
    String? error,
  }) {
    if (!captureEnabled) {
      return;
    }

    _entries.add(
      NetworkLogEntry(
        timestamp: timestamp,
        method: method,
        uri: uri,
        duration: duration,
        requestHeaders: _redactHeaders(requestHeaders),
        requestBody: _sanitizeBody(requestBody),
        statusCode: statusCode,
        responseHeaders: _redactHeaders(responseHeaders),
        responseBody: _sanitizeBody(responseBody),
        error: _sanitizeBody(error),
      ),
    );

    if (_entries.length > _maxEntries) {
      _entries.removeRange(0, _entries.length - _maxEntries);
    }
    _entriesController.add(List.unmodifiable(_entries));
  }

  Map<String, String> _redactHeaders(Map<String, String> headers) {
    return Map.unmodifiable(
      headers.map(
        (key, value) => MapEntry(
          key,
          _redactedHeaders.contains(key.toLowerCase()) ? _redactedValue : value,
        ),
      ),
    );
  }

  String? _sanitizeBody(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }

    final normalizedValue = value.trim();
    if (normalizedValue.isEmpty) {
      return null;
    }

    final prettyValue = _tryPrettyJson(normalizedValue) ?? normalizedValue;
    if (prettyValue.length <= _maxBodyLength) {
      return prettyValue;
    }

    return '${prettyValue.substring(0, _maxBodyLength)}\n...truncated';
  }

  String? _tryPrettyJson(String value) {
    try {
      final decoded = jsonDecode(value);
      return const JsonEncoder.withIndent('  ').convert(decoded);
    } catch (_) {
      return null;
    }
  }
}
