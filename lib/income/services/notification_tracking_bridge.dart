import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationTrackingBridge {
  static const _methodChannel = MethodChannel(
    'jabhouy/notification_tracking/methods',
  );
  static const _eventChannel = EventChannel(
    'jabhouy/notification_tracking/events',
  );
  static const _diagnosticLogChannel = EventChannel(
    'jabhouy/notification_tracking/logs',
  );
  static const _pendingKey = 'pending_notifications';
  static const _uploadedKey = 'uploaded_notification_fingerprints';

  bool get isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Stream<Map<String, dynamic>> get notificationStream {
    if (!isSupported) return const Stream.empty();
    return _eventChannel.receiveBroadcastStream().map(_toMap).where(
          (event) => event.isNotEmpty,
        );
  }

  Stream<Map<String, dynamic>> get diagnosticLogStream {
    if (!isSupported) return const Stream.empty();
    return _diagnosticLogChannel.receiveBroadcastStream().map(_toMap).where(
          (event) => event.isNotEmpty,
        );
  }

  Future<bool> isNotificationAccessEnabled() async {
    if (!isSupported) return false;
    return await _methodChannel.invokeMethod<bool>(
          'isNotificationAccessEnabled',
        ) ??
        false;
  }

  Future<void> openNotificationAccessSettings() async {
    if (!isSupported) return;
    await _methodChannel.invokeMethod<void>('openNotificationAccessSettings');
  }

  Future<List<Map<String, dynamic>>> drainPendingTrackedNotifications() async {
    if (!isSupported) return const [];
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_pendingKey);
    if (raw == null || raw.isEmpty) {
      return const [];
    }

    await prefs.remove(_pendingKey);
    await prefs.remove(_uploadedKey);

    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      return const [];
    }

    return decoded
        .whereType<Map<dynamic, dynamic>>()
        .map(Map<String, dynamic>.from)
        .toList(growable: false);
  }

  Future<void> pushDemoNotifications() async {
    if (!isSupported) return;
    await _methodChannel.invokeMethod<void>('pushDemoNotifications');
  }

  Future<List<Map<String, dynamic>>> getDiagnosticsLogs() async {
    if (!isSupported) return const [];
    final result = await _methodChannel.invokeMethod<List<dynamic>>(
      'getDiagnosticsLogs',
    );
    if (result == null) {
      return const [];
    }

    return result
        .map(_toMap)
        .where((entry) => entry.isNotEmpty)
        .toList(growable: false);
  }

  Future<void> clearDiagnosticsLogs() async {
    if (!isSupported) return;
    await _methodChannel.invokeMethod<void>('clearDiagnosticsLogs');
  }

  Future<void> clearStoredTrackingState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pendingKey);
    await prefs.remove(_uploadedKey);
  }

  Future<void> appendDiagnosticsLog({
    required String source,
    required String message,
    String level = 'info',
    Map<String, dynamic>? metadata,
  }) async {
    if (!isSupported) return;
    await _methodChannel.invokeMethod<void>('appendDiagnosticsLog', {
      'source': source,
      'message': message,
      'level': level,
      'metadata': metadata ?? <String, dynamic>{},
    });
  }

  Map<String, dynamic> _toMap(dynamic event) {
    if (event is Map<Object?, Object?>) {
      return Map<String, dynamic>.from(event);
    }
    if (event is String) {
      final decoded = jsonDecode(event);
      return Map<String, dynamic>.from(decoded as Map);
    }
    return <String, dynamic>{};
  }
}
