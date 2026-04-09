import 'dart:async';
import 'dart:math';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:my_app/app/app.dart';
import 'package:my_app/auth/auth.dart';
import 'package:my_app/income/models/bank_notification_model.dart';
import 'package:my_app/income/services/notification_diagnostics_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

typedef LocalNotificationsLoader = Future<List<BankNotificationModel>>
    Function();
typedef NotificationSyncStatusUpdater = Future<void> Function(
  String fingerprint,
  int syncStatus,
);

class MainDeviceClaimStatus {
  const MainDeviceClaimStatus({
    required this.isActiveOnThisDevice,
    required this.isClaimedByAnotherDevice,
  });

  final bool isActiveOnThisDevice;
  final bool isClaimedByAnotherDevice;
}

class FirebaseIncomeSyncService {
  FirebaseIncomeSyncService(
    this._connectivityService,
    this._authService,
    this._fcmService,
    this._diagnostics,
  );

  static const _deviceIdKey = 'income_sync_device_id';
  static const _nativeScopeIdKey = 'income_sync_scope_id';

  final ConnectivityService _connectivityService;
  final AuthService _authService;
  final FcmService _fcmService;
  final NotificationDiagnosticsService _diagnostics;
  final _deviceRoleController = StreamController<DeviceRole>.broadcast();

  StreamSubscription<bool>? _connectivitySubscription;
  LocalNotificationsLoader? _loadLocalNotifications;
  NotificationSyncStatusUpdater? _updateNotificationSyncStatus;
  String? _scopeId;
  bool _initialized = false;
  bool _isSyncingLocalBacklog = false;

  bool get isConfigured => Firebase.apps.isNotEmpty;
  Stream<DeviceRole> get deviceRoleStream => _deviceRoleController.stream;

  Future<void> initialize({
    required LocalNotificationsLoader loadLocalNotifications,
    required NotificationSyncStatusUpdater updateNotificationSyncStatus,
  }) async {
    _loadLocalNotifications = loadLocalNotifications;
    _updateNotificationSyncStatus = updateNotificationSyncStatus;

    if (_initialized) {
      await _syncLocalBacklog();
      return;
    }

    _initialized = true;
    _connectivitySubscription = _connectivityService.connectivityStream.listen(
      (isOnline) {
        if (isOnline) {
          unawaited(_syncLocalBacklog());
        }
      },
    );

    await _prepareSync();
    await _syncLocalBacklog();
  }

  Future<bool> syncNotification(BankNotificationModel model) async {
    if (!await _shouldUploadLocalChanges()) {
      await _diagnostics.log(
        source: 'flutter.firebase_sync',
        message:
            'Skipped remote notification sync because this device cannot upload local changes right now.',
        level: 'warning',
        metadata: {
          'fingerprint': model.fingerprint,
          'packageName': model.packageName,
        },
      );
      return false;
    }

    await _prepareSync();
    final didSync =
        await sendTestNotification(_notificationPayloadFromModel(model));

    if (didSync) {
      await _diagnostics.log(
        source: 'flutter.firebase_sync',
        message: 'Synced notification through backend test notification flow.',
        metadata: {
          'fingerprint': model.fingerprint,
        },
      );
    }
    return didSync;
  }

  Future<void> dispose() async {
    await _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
    _loadLocalNotifications = null;
    _updateNotificationSyncStatus = null;
    _scopeId = null;
    _initialized = false;
    _isSyncingLocalBacklog = false;
  }

  Future<void> clearPersistedSessionState() async {
    if (await _connectivityService.isOnline) {
      await _fcmService.unregisterToken();
    }

    await dispose();

    final sharedPreferences = await SharedPreferences.getInstance();
    await sharedPreferences.remove('deviceRole');
    await sharedPreferences.remove(_nativeScopeIdKey);

    _deviceRoleController.add(DeviceRole.sub);
  }

  Future<DeviceRole> getStoredDeviceRole() async {
    final sharedPreferences = await SharedPreferences.getInstance();
    return DeviceRole.fromStorage(sharedPreferences.getString('deviceRole'));
  }

  Future<bool> requestMainDeviceRole() async {
    await _persistDeviceRole(DeviceRole.main);
    await _diagnostics.log(
      source: 'flutter.firebase_sync',
      message: 'Promoted device to main role.',
    );
    return true;
  }

  Future<void> releaseMainDeviceRole() async {
    await _persistDeviceRole(DeviceRole.sub);
    await _diagnostics.log(
      source: 'flutter.firebase_sync',
      message: 'Released main device role.',
    );
  }

  Future<DeviceRole> refreshDeviceRole() async {
    return getStoredDeviceRole();
  }

  Future<MainDeviceClaimStatus> getMainDeviceClaimStatus() async {
    final deviceRole = await getStoredDeviceRole();
    final claimStatus = MainDeviceClaimStatus(
      isActiveOnThisDevice: deviceRole.isMain,
      isClaimedByAnotherDevice: false,
    );
    return claimStatus;
  }

  Future<bool> canAcceptLocalCapture() async {
    return (await getStoredDeviceRole()).isMain;
  }

  Future<void> _syncLocalBacklog() async {
    if (_isSyncingLocalBacklog || !await _shouldUploadLocalChanges()) return;

    final loader = _loadLocalNotifications;
    final updateNotificationSyncStatus = _updateNotificationSyncStatus;
    if (loader == null || updateNotificationSyncStatus == null) return;

    _isSyncingLocalBacklog = true;
    try {
      final items = await loader();
      for (final item in items) {
        final didSync = await syncNotification(item);
        await updateNotificationSyncStatus(
          item.fingerprint,
          didSync ? 0 : 2,
        );
      }
    } finally {
      _isSyncingLocalBacklog = false;
    }
  }

  Future<void> _prepareSync() async {
    if (_scopeId == null) {
      final scopeId = await _resolveScopeId();
      if (scopeId == null || scopeId.isEmpty) {
        await _persistNativeScopeId(null);
        logger.i(
          'Firebase income sync skipped because no scope id is available.',
        );
        await _diagnostics.log(
          source: 'flutter.firebase_sync',
          message:
              'Skipped Firebase income sync because no scope id is available.',
          level: 'warning',
        );
        return;
      }

      _scopeId = scopeId;
      await _persistNativeScopeId(scopeId);

      if (isConfigured) {
        final deviceRole = await getStoredDeviceRole();
        unawaited(_syncCurrentTokenRegistration(deviceRole));
      }
    }
  }

  Future<bool> sendTestNotification(Map<String, dynamic> payload) async {
    if (!await _shouldUploadLocalChanges()) {
      await _diagnostics.log(
        source: 'flutter.firebase_sync',
        message:
            'Skipped demo push notification because this device cannot upload local changes right now.',
        level: 'warning',
      );
      return false;
    }

    final content = FcmService.buildNotificationContentFromPayload(payload);
    final response = await _fcmService.sendTestNotification(
      title: content.title,
      body: content.body,
      data: {
        'fingerprint': payload['fingerprint']?.toString() ?? '',
        'bankKey': payload['bankKey']?.toString() ?? '',
        'amount': payload['amount']?.toString() ?? '',
        'currency': payload['currency']?.toString() ?? '',
        'isIncome': payload['isIncome']?.toString() ?? 'true',
        'message': payload['message']?.toString() ?? '',
        'title': payload['title']?.toString() ?? '',
      },
    );

    await _diagnostics.log(
      source: 'flutter.firebase_sync',
      message: response.success
          ? 'Sent push notification through backend test endpoint.'
          : 'Failed to send push notification through backend test endpoint.',
      level: response.success ? 'info' : 'warning',
      metadata: {
        'fingerprint': payload['fingerprint'],
        'attempted': response.data?['attempted'],
        'succeeded': response.data?['succeeded'],
        'failed': response.data?['failed'],
        'pruned': response.data?['pruned'],
        'message': response.message,
      },
    );
    return response.success;
  }

  Map<String, dynamic> _notificationPayloadFromModel(
    BankNotificationModel model,
  ) =>
      {
        'fingerprint': model.fingerprint,
        'packageName': model.packageName,
        'bankKey': model.bankApp.key,
        'title': model.title ?? '',
        'message': model.message,
        'amount': model.amount,
        'currency': model.currency,
        'isIncome': model.isIncome,
        'receivedAt': model.receivedAt.millisecondsSinceEpoch,
        'source': model.source,
      };

  Future<String?> _resolveScopeId() async {
    final configuredScope = _readEnv('FIREBASE_INCOME_SCOPE_ID');
    if (configuredScope != null) {
      return configuredScope;
    }

    final user = await _authService.getCachedUser();
    return user?.id ?? user?.email ?? user?.username;
  }

  Future<bool> _shouldUploadLocalChanges() async {
    if (!await _connectivityService.isOnline) return false;
    return (await getStoredDeviceRole()).isMain;
  }

  String? _readEnv(String key) {
    final value = dotenv.maybeGet(key)?.trim();
    if (value == null || value.isEmpty) {
      return null;
    }
    return value;
  }

  Future<void> _persistDeviceRole(DeviceRole deviceRole) async {
    final sharedPreferences = await SharedPreferences.getInstance();
    final previousRole =
        DeviceRole.fromStorage(sharedPreferences.getString('deviceRole'));
    if (previousRole == deviceRole) {
      return;
    }

    await sharedPreferences.setString('deviceRole', deviceRole.storageValue);
    _deviceRoleController.add(deviceRole);
    await _registerCurrentToken(deviceRole);
  }

  Future<void> _persistNativeScopeId(String? scopeId) async {
    final sharedPreferences = await SharedPreferences.getInstance();
    if (scopeId == null || scopeId.isEmpty) {
      await sharedPreferences.remove(_nativeScopeIdKey);
      return;
    }
    await sharedPreferences.setString(_nativeScopeIdKey, scopeId);
  }

  Future<String> _getOrCreateDeviceId() async {
    final sharedPreferences = await SharedPreferences.getInstance();
    final savedId = sharedPreferences.getString(_deviceIdKey);
    if (savedId != null && savedId.isNotEmpty) {
      return savedId;
    }

    final random = Random.secure();
    final buffer = StringBuffer(DateTime.now().millisecondsSinceEpoch);
    for (var index = 0; index < 6; index++) {
      buffer.write(random.nextInt(16).toRadixString(16));
    }
    final deviceId = buffer.toString();
    await sharedPreferences.setString(_deviceIdKey, deviceId);
    return deviceId;
  }

  Future<void> _registerCurrentToken(DeviceRole deviceRole) async {
    if (!isConfigured) return;

    final scopeId = _scopeId ?? await _resolveScopeId();
    if (scopeId == null || scopeId.isEmpty) return;

    _scopeId = scopeId;
    await _syncCurrentTokenRegistration(deviceRole);
  }

  Future<void> _syncCurrentTokenRegistration(DeviceRole deviceRole) async {
    if (deviceRole.isMain) {
      await _fcmService.unregisterToken();
      return;
    }

    final deviceId = await _getOrCreateDeviceId();
    await _fcmService.registerToken(
      deviceId: deviceId,
      deviceRole: deviceRole.storageValue,
    );
  }
}
