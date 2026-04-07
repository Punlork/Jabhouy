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
  static const _pendingKey = 'pending_notifications';
  static const _uploadedKey = 'uploaded_notification_fingerprints';

  bool get isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Stream<Map<String, dynamic>> get notificationStream {
    if (!isSupported) return const Stream.empty();
    return _eventChannel.receiveBroadcastStream().map((event) {
      if (event is Map<Object?, Object?>) {
        return Map<String, dynamic>.from(event);
      }
      if (event is String) {
        final decoded = jsonDecode(event);
        return Map<String, dynamic>.from(decoded as Map);
      }
      return <String, dynamic>{};
    }).where((event) => event.isNotEmpty);
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
}
