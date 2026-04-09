import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

class AppLogEntry {
  const AppLogEntry({
    required this.timestamp,
    required this.level,
    required this.source,
    required this.message,
    this.details,
  });

  final DateTime timestamp;
  final String level;
  final String source;
  final String message;
  final String? details;
}

class AppLogService {
  AppLogService._internal() {
    Logger.addLogListener(_handleLoggerEvent);
  }

  static final AppLogService instance = AppLogService._internal();
  static const _maxEntries = 250;
  static final _ansiEscapePattern = RegExp(r'\x1B\[[0-9;]*m');

  final _entries = <AppLogEntry>[];
  final _entriesController = StreamController<List<AppLogEntry>>.broadcast();

  bool captureEnabled = !kReleaseMode;
  List<AppLogEntry> get entries => List.unmodifiable(_entries);
  Stream<List<AppLogEntry>> get entriesStream => _entriesController.stream;

  void capturePrint(String message) {
    if (_isLoggerConsoleLine(message)) {
      return;
    }

    _addEntry(
      AppLogEntry(
        timestamp: DateTime.now(),
        level: 'print',
        source: 'dart.print',
        message: message,
      ),
    );
  }

  void captureMessage({
    required String level,
    required String source,
    required String message,
    String? details,
  }) {
    _addEntry(
      AppLogEntry(
        timestamp: DateTime.now(),
        level: level,
        source: source,
        message: message,
        details: details,
      ),
    );
  }

  void clear() {
    _entries.clear();
    _entriesController.add(List.unmodifiable(_entries));
  }

  void _handleLoggerEvent(LogEvent event) {
    final detailsBuffer = StringBuffer();
    if (event.error != null) {
      detailsBuffer.writeln('Error: ${event.error}');
    }
    if (event.stackTrace != null) {
      detailsBuffer.write('Stack trace:\n${event.stackTrace}');
    }

    _addEntry(
      AppLogEntry(
        timestamp: event.time,
        level: event.level.name,
        source: 'logger',
        message: '${event.message}',
        details: detailsBuffer.isEmpty ? null : detailsBuffer.toString(),
      ),
    );
  }

  void _addEntry(AppLogEntry entry) {
    if (!captureEnabled) {
      return;
    }

    _entries.add(entry);
    if (_entries.length > _maxEntries) {
      _entries.removeRange(0, _entries.length - _maxEntries);
    }
    _entriesController.add(List.unmodifiable(_entries));
  }

  bool _isLoggerConsoleLine(String message) {
    const loggerPrefixes = {
      '┌',
      '└',
      '├',
      '│',
      '┄',
      '─',
      '🐛',
      '💡',
      '⚠️',
      '⛔',
      '👾',
    };
    final trimmed = message.replaceAll(_ansiEscapePattern, '').trimLeft();
    if (trimmed.isEmpty) {
      return false;
    }

    return loggerPrefixes.any(trimmed.startsWith);
  }
}
