import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class NotificationTrackingBridge {
  static const _methodChannel = MethodChannel(
    'jabhouy/notification_tracking/methods',
  );
  static const _eventChannel = EventChannel(
    'jabhouy/notification_tracking/events',
  );

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
    final result = await _methodChannel.invokeMethod<List<dynamic>>(
      'drainPendingTrackedNotifications',
    );
    if (result == null) return const [];

    return result
        .whereType<Map<Object?, Object?>>()
        .map(Map<String, dynamic>.from)
        .toList(growable: false);
  }

  Future<void> pushDemoNotifications() async {
    if (!isSupported) return;
    await _methodChannel.invokeMethod<void>('pushDemoNotifications');
  }
}
