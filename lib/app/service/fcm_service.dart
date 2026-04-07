import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:my_app/app/utils/logger.dart';
import 'package:my_app/income/models/bank_notification_model.dart';

/// Top-level handler required by firebase_messaging for background/terminated
/// state. Must be annotated with @pragma('vm:entry-point').
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // The OS will display the notification automatically when the `notification`
  // payload is present. No extra work needed here for dev mode.
  logger.d('FCM background message received: ${message.messageId}');
}

class FcmService {
  static const _channelId = 'income_push';
  static const _channelName = 'Income Notifications';
  static const _scopesCollection = 'income_sync_scopes';
  static const _tokensCollection = '_fcm_tokens';

  final _localNotifications = FlutterLocalNotificationsPlugin();
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
    } catch (error, stackTrace) {
      logger.e(
        'Failed to register FCM token.',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// Show a local push notification derived from a Firestore income payload.
  Future<void> showIncomeNotification(Map<String, dynamic> payload) async {
    final bank = BankApp.fromKey(payload['bankKey'] as String? ?? '');
    final amount = payload['amount'];
    final currency = payload['currency'] as String? ?? 'USD';
    final isIncome = payload['isIncome'] as bool? ?? true;
    final fingerprint = payload['fingerprint'] as String? ?? '';

    final sign = isIncome ? '+' : '-';
    final amountStr =
        amount != null ? '$sign$amount $currency' : currency;

    await _showLocalNotification(
      id: fingerprint.hashCode.abs(),
      title: isIncome
          ? 'Income: ${bank.label}'
          : 'Expense: ${bank.label}',
      body: amountStr,
    );
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  Future<void> _setupLocalNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
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
    final notification = message.notification;
    if (notification == null) return;

    unawaited(
      _showLocalNotification(
        id: message.messageId.hashCode.abs(),
        title: notification.title ?? 'New Income',
        body: notification.body ?? '',
      ),
    );
  }

  Future<void> _showLocalNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: 'Income notifications from the main device.',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    await _localNotifications.show(
      id,
      title,
      body,
      const NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      ),
    );
  }
}
