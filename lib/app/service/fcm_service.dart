import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:my_app/app/utils/logger.dart';
import 'package:my_app/income/models/bank_notification_model.dart';
import 'package:my_app/income/services/notification_diagnostics_service.dart';

/// Top-level handler required by firebase_messaging for background/terminated
/// state. Must be annotated with @pragma('vm:entry-point').
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // The OS will display the notification automatically when the `notification`
  // payload is present. No extra work needed here for dev mode.
  logger.d('FCM background message received: ${message.messageId}');
}

class FcmNotificationContent {
  const FcmNotificationContent({
    required this.title,
    required this.body,
    required this.groupKey,
  });

  final String title;
  final String body;
  final String groupKey;
}

class FcmService {
  FcmService(this._diagnostics);

  static const _channelId = 'income_push';
  static const _channelName = 'Income Notifications';
  static const _androidNotificationIcon = 'ic_launcher_foreground';
  static const _scopesCollection = 'income_sync_scopes';
  static const _tokensCollection = '_fcm_tokens';
  static const _incomeGroupKey = 'income_updates';
  static const _syncGroupKey = 'sync_updates';

  final NotificationDiagnosticsService _diagnostics;
  final _localNotifications = FlutterLocalNotificationsPlugin();
  final _recentNotificationKeys = <String>{};
  final _recentNotificationOrder = <String>[];
  bool _initialized = false;

  bool get _isFirebaseAvailable => Firebase.apps.isNotEmpty;

  /// Register the background message handler. Call this once at the very
  /// beginning of main(), before [Firebase.initializeApp].
  static void setupBackgroundHandler() {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  /// Initialise local notifications and request FCM permission.
  /// Safe to call multiple times (idempotent).
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    await _setupLocalNotifications();
    if (!_isFirebaseAvailable) return;

    final settings = await FirebaseMessaging.instance.requestPermission();
    logger.d('FCM permission status: ${settings.authorizationStatus}');

    // Show a local notification when a FCM message arrives in the foreground
    // (FCM does not show a heads-up notification on its own in foreground).
    FirebaseMessaging.onMessage.listen(_onForegroundFcmMessage);
  }

  /// Save this device's FCM token and role under
  /// `income_sync_scopes/{scopeId}/_fcm_tokens/{deviceId}`.
  /// The Cloud Function reads [deviceRole] to only push to sub devices.
  Future<void> registerToken({
    required String scopeId,
    required String deviceId,
    required String deviceRole,
  }) async {
    if (!_isFirebaseAvailable) return;

    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) return;

      // print all data as json for backend to test
      // ignore: leading_newlines_in_multiline_strings
      final data = {
        'scopeId': scopeId,
        'deviceId': deviceId,
        'deviceRole': deviceRole,
        'token': token,
      };

      logger.d('''FCM token data: $data''');
      await _diagnostics.log(
        source: 'flutter.fcm',
        message: 'Prepared FCM token payload for backend registration.',
        metadata: data,
      );

      await FirebaseFirestore.instance
          .collection(_scopesCollection)
          .doc(scopeId)
          .collection(_tokensCollection)
          .doc(deviceId)
          .set(
        <String, dynamic>{
          'fcmToken': token,
          'deviceRole': deviceRole,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      logger.d(
        'FCM token saved for $deviceRole device $deviceId (scope: $scopeId)',
      );
      await _diagnostics.log(
        source: 'flutter.fcm',
        message: 'Saved FCM token for device.',
        metadata: {
          'scopeId': scopeId,
          'deviceId': deviceId,
          'deviceRole': deviceRole,
        },
      );
    } catch (error, stackTrace) {
      logger.e(
        'Failed to register FCM token.',
        error: error,
        stackTrace: stackTrace,
      );
      await _diagnostics.log(
        source: 'flutter.fcm',
        message: 'Failed to register FCM token.',
        level: 'error',
        metadata: {
          'scopeId': scopeId,
          'deviceId': deviceId,
          'deviceRole': deviceRole,
          'error': error.toString(),
        },
      );
    }
  }

  /// Show a local push notification derived from a Firestore income payload.
  Future<void> showIncomeNotification(Map<String, dynamic> payload) async {
    final fingerprint = payload['fingerprint'] as String? ?? '';
    if (!_rememberNotificationKey(fingerprint)) return;
    final content = buildNotificationContentFromPayload(payload);

    await _showLocalNotification(
      id: fingerprint.hashCode.abs(),
      title: content.title,
      body: content.body,
      groupKey: content.groupKey,
    );
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  Future<void> _setupLocalNotifications() async {
    const androidSettings =
        AndroidInitializationSettings(_androidNotificationIcon);
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _localNotifications.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
    );

    // Create the Android notification channel once.
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            _channelId,
            _channelName,
            description:
                'Push notifications for income transactions from the main device.',
            importance: Importance.high,
          ),
        );
  }

  void _onForegroundFcmMessage(RemoteMessage message) {
    final key = _notificationKeyFromRemoteMessage(message);
    if (!_rememberNotificationKey(key)) return;
    final content = buildNotificationContentFromRemoteMessage(message);

    unawaited(
      _showLocalNotification(
        id: key.hashCode.abs(),
        title: content.title,
        body: content.body,
        groupKey: content.groupKey,
      ),
    );
  }

  Future<void> _showLocalNotification({
    required int id,
    required String title,
    required String body,
    required String groupKey,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: 'Income notifications from the main device.',
      importance: Importance.high,
      priority: Priority.high,
      icon: _androidNotificationIcon,
      groupKey: groupKey,
      category: AndroidNotificationCategory.message,
      styleInformation: BigTextStyleInformation(body),
    );

    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      threadIdentifier: groupKey,
    );

    await _localNotifications.show(
      id,
      title,
      body,
      NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      ),
    );
  }

  static FcmNotificationContent buildNotificationContentFromPayload(
    Map<String, dynamic> payload,
  ) {
    final bank = BankApp.fromKey(payload['bankKey'] as String? ?? '');
    final amount = payload['amount'];
    final currency = payload['currency'] as String? ?? 'USD';
    final isIncome = payload['isIncome'] as bool? ?? true;
    final fallbackMessage =
        payload['message'] as String? ?? payload['title'] as String?;
    final bankLabel = bank == BankApp.unknown ? 'Bank update' : bank.label;
    final parsedAmount = _parseAmount(amount);
    final formattedAmount = parsedAmount == null
        ? null
        : BankNotificationModel.formatAmount(
            amount: parsedAmount,
            currency: currency,
          );

    return FcmNotificationContent(
      title: isIncome ? 'Income received' : 'Expense recorded',
      body: formattedAmount != null
          ? '$bankLabel • $formattedAmount'
          : _compactNotificationText(fallbackMessage) ?? bankLabel,
      groupKey: _incomeGroupKey,
    );
  }

  static FcmNotificationContent buildNotificationContentFromRemoteMessage(
    RemoteMessage message,
  ) {
    if (message.data.containsKey('bankKey') ||
        message.data.containsKey('isIncome') ||
        message.data.containsKey('fingerprint')) {
      return buildNotificationContentFromPayload(message.data);
    }

    final notification = message.notification;
    final title = notification?.title?.trim();
    final body = notification?.body?.trim();

    return FcmNotificationContent(
      title: title == null || title.isEmpty ? 'Income update' : title,
      body: body == null || body.isEmpty
          ? 'Open the app to review the latest activity.'
          : _compactNotificationText(body) ?? body,
      groupKey: _syncGroupKey,
    );
  }

  static String? _compactNotificationText(String? text) {
    final normalized = text?.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (normalized == null || normalized.isEmpty) {
      return null;
    }

    const maxLength = 72;
    if (normalized.length <= maxLength) {
      return normalized;
    }
    return '${normalized.substring(0, maxLength - 1)}…';
  }

  static double? _parseAmount(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value.replaceAll(',', '').trim());
    }
    return null;
  }

  String _notificationKeyFromRemoteMessage(RemoteMessage message) {
    return message.data['fingerprint']?.toString() ??
        message.messageId ??
        '${message.sentTime?.millisecondsSinceEpoch ?? 0}:${message.notification?.title ?? ''}:${message.notification?.body ?? ''}';
  }

  bool _rememberNotificationKey(String key) {
    if (key.isEmpty) return true;
    if (_recentNotificationKeys.contains(key)) {
      return false;
    }

    _recentNotificationKeys.add(key);
    _recentNotificationOrder.add(key);
    if (_recentNotificationOrder.length > 50) {
      final removed = _recentNotificationOrder.removeAt(0);
      _recentNotificationKeys.remove(removed);
    }
    return true;
  }
}
