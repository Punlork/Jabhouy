import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:my_app/app/app.dart';
import 'package:my_app/auth/auth.dart';
import 'package:my_app/income/models/bank_notification_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

typedef RemoteNotificationHandler = Future<void> Function(
  Map<String, dynamic> payload,
);
typedef LocalNotificationsLoader = Future<List<BankNotificationModel>>
    Function();

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
    this._apiService,
  );

  static const _collectionName = 'income_sync_scopes';
  static const _systemCollectionName = '_system';
  static const _mainDeviceClaimDocumentId = 'main_device';
  static const _deviceIdKey = 'income_sync_device_id';
  static const _mainClaimStaleDuration = Duration(minutes: 2);

  final ConnectivityService _connectivityService;
  final AuthService _authService;
  final FcmService _fcmService;
  final ApiService _apiService;

  StreamSubscription<bool>? _connectivitySubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _remoteSubscription;
  RemoteNotificationHandler? _onRemotePayload;
  LocalNotificationsLoader? _loadLocalNotifications;
  String? _scopeId;
  bool _initialized = false;
  bool _isFirstSnapshot = true;
  MainDeviceClaimStatus? _cachedMainDeviceClaimStatus;

  bool get isConfigured => Firebase.apps.isNotEmpty;

  Future<void> initialize({
    required RemoteNotificationHandler onRemotePayload,
    required LocalNotificationsLoader loadLocalNotifications,
  }) async {
    _onRemotePayload = onRemotePayload;
    _loadLocalNotifications = loadLocalNotifications;

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

  Future<void> syncNotification(BankNotificationModel model) async {
    if (!await _shouldUploadLocalChanges()) return;

    final collection = await _prepareCollection();
    if (collection == null) return;

    await collection.doc(model.fingerprint).set(
          _toRemoteMap(model),
          SetOptions(merge: true),
        );

    unawaited(_pushNotifySubDevices(model));
  }

  Future<void> _pushNotifySubDevices(BankNotificationModel model) async {
    final scopeId = _scopeId;
    if (scopeId == null) return;

    await _apiService.post<void>(
      '/income/notify',
      showSnackBar: false,
      body: {
        'scopeId': scopeId,
        'bankKey': model.bankApp.key,
        'amount': model.amount,
        'currency': model.currency,
        'isIncome': model.isIncome,
        'fingerprint': model.fingerprint,
      },
    );
  }

  Future<void> dispose() async {
    await _remoteSubscription?.cancel();
    await _connectivitySubscription?.cancel();
    _remoteSubscription = null;
    _connectivitySubscription = null;
    _onRemotePayload = null;
    _loadLocalNotifications = null;
    _scopeId = null;
    _initialized = false;
    _isFirstSnapshot = true;
    _cachedMainDeviceClaimStatus = null;
  }

  Future<MainDeviceClaimStatus> getMainDeviceClaimStatus() async {
    final deviceRole = await _getDeviceRole();
    if (deviceRole.isSub) {
      await _releaseMainDeviceClaimIfOwned();
      return const MainDeviceClaimStatus(
        isActiveOnThisDevice: false,
        isClaimedByAnotherDevice: false,
      );
    }

    if (!isConfigured) {
      return const MainDeviceClaimStatus(
        isActiveOnThisDevice: true,
        isClaimedByAnotherDevice: false,
      );
    }

    final scopeId = await _resolveScopeId();
    if (scopeId == null || scopeId.isEmpty) {
      return const MainDeviceClaimStatus(
        isActiveOnThisDevice: true,
        isClaimedByAnotherDevice: false,
      );
    }

    if (!await _connectivityService.isOnline) {
      return _cachedMainDeviceClaimStatus ??
          const MainDeviceClaimStatus(
            isActiveOnThisDevice: true,
            isClaimedByAnotherDevice: false,
          );
    }

    final claimStatus = await _claimMainDevice(scopeId);
    _cachedMainDeviceClaimStatus = claimStatus;
    return claimStatus;
  }

  Future<bool> canAcceptLocalCapture() async {
    final deviceRole = await _getDeviceRole();
    if (deviceRole.isSub) return false;

    if (!isConfigured) return true;

    if (!await _connectivityService.isOnline) {
      return _cachedMainDeviceClaimStatus?.isActiveOnThisDevice ?? true;
    }

    final claimStatus = await getMainDeviceClaimStatus();
    return claimStatus.isActiveOnThisDevice;
  }

  Future<void> _syncLocalBacklog() async {
    if (!await _shouldUploadLocalChanges()) return;

    final loader = _loadLocalNotifications;
    if (loader == null) return;

    final collection = await _prepareCollection();
    if (collection == null) return;

    final items = await loader();
    for (final item in items) {
      await collection.doc(item.fingerprint).set(
            _toRemoteMap(item),
            SetOptions(merge: true),
          );
    }
  }

  Future<CollectionReference<Map<String, dynamic>>?>
      _prepareCollection() async {
    await _prepareSync();
    final scopeId = _scopeId;
    if (!isConfigured || scopeId == null) return null;

    return FirebaseFirestore.instance
        .collection(_collectionName)
        .doc(scopeId)
        .collection('notifications');
  }

  Future<void> _prepareSync() async {
    if (!isConfigured) return;
    if (_scopeId != null) return;

    final scopeId = await _resolveScopeId();
    if (scopeId == null || scopeId.isEmpty) {
      logger.i(
        'Firebase income sync skipped because no scope id is available.',
      );
      return;
    }

    _scopeId = scopeId;

    // Register this device's FCM token so the Cloud Function can push to sub devices.
    final deviceId = await _getOrCreateDeviceId();
    final deviceRole = await _getDeviceRole();
    unawaited(
      _fcmService.registerToken(
        scopeId: scopeId,
        deviceId: deviceId,
        deviceRole: deviceRole.storageValue,
      ),
    );

    final collection = FirebaseFirestore.instance
        .collection(_collectionName)
        .doc(scopeId)
        .collection('notifications');

    _remoteSubscription = collection.snapshots().listen(
      _onRemoteSnapshot,
      onError: (Object error, StackTrace stackTrace) {
        logger.e(
          'Firebase income sync listener failed.',
          error: error,
          stackTrace: stackTrace,
        );
      },
    );
  }

  Future<String?> _resolveScopeId() async {
    final configuredScope = _readEnv('FIREBASE_INCOME_SCOPE_ID');
    if (configuredScope != null) {
      return configuredScope;
    }

    final user = await _authService.getCachedUser();
    return user?.id ?? user?.email ?? user?.username;
  }

  Future<bool> _shouldUploadLocalChanges() async {
    if (!isConfigured) return false;
    if (!await _connectivityService.isOnline) return false;

    final claimStatus = await getMainDeviceClaimStatus();
    return claimStatus.isActiveOnThisDevice;
  }

  void _onRemoteSnapshot(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    final remoteHandler = _onRemotePayload;
    if (remoteHandler == null) return;

    // Skip the initial batch so we don't show notifications for existing data
    // that was already stored before this session.
    final isInitialLoad = _isFirstSnapshot;
    _isFirstSnapshot = false;

    for (final change in snapshot.docChanges) {
      if (change.type == DocumentChangeType.removed) {
        continue;
      }

      final data = change.doc.data();
      if (data == null) continue;

      final payload = Map<String, dynamic>.from(data)
        ..putIfAbsent('fingerprint', () => change.doc.id);

      unawaited(remoteHandler(payload));

      // Notify sub device of a new income transaction pushed by the main device.
      if (!isInitialLoad && change.type == DocumentChangeType.added) {
        unawaited(_notifySubDeviceIfNeeded(payload));
      }
    }
  }

  Future<void> _notifySubDeviceIfNeeded(Map<String, dynamic> payload) async {
    final deviceRole = await _getDeviceRole(); 
    if (deviceRole.isSub) {
      await _fcmService.showIncomeNotification(payload);
    }
  }

  Map<String, dynamic> _toRemoteMap(BankNotificationModel model) {
    return <String, dynamic>{
      'fingerprint': model.fingerprint,
      'packageName': model.packageName,
      'bankKey': model.bankApp.key,
      'title': model.title,
      'message': model.message,
      'rawPayload': model.rawPayload,
      'amount': model.amount,
      'currency': model.currency,
      'isIncome': model.isIncome,
      'receivedAt': model.receivedAt.millisecondsSinceEpoch,
      'source': model.source,
      'createdAt': model.createdAt.toIso8601String(),
      'syncedAt': FieldValue.serverTimestamp(),
    };
  }

  String? _readEnv(String key) {
    final value = dotenv.maybeGet(key)?.trim();
    if (value == null || value.isEmpty) {
      return null;
    }
    return value;
  }

  Future<DeviceRole> _getDeviceRole() async {
    final sharedPreferences = await SharedPreferences.getInstance();
    return DeviceRole.fromStorage(sharedPreferences.getString('deviceRole'));
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

  DocumentReference<Map<String, dynamic>> _mainDeviceClaimRef(String scopeId) {
    return FirebaseFirestore.instance
        .collection(_collectionName)
        .doc(scopeId)
        .collection(_systemCollectionName)
        .doc(_mainDeviceClaimDocumentId);
  }

  Future<MainDeviceClaimStatus> _claimMainDevice(String scopeId) async {
    final claimRef = _mainDeviceClaimRef(scopeId);
    final deviceId = await _getOrCreateDeviceId();
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    return FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(claimRef);
      final data = snapshot.data();
      final claimedDeviceId = data?['deviceId'] as String?;
      final updatedAtMs = data?['updatedAtMs'] as int? ?? 0;
      final isStale =
          nowMs - updatedAtMs > _mainClaimStaleDuration.inMilliseconds;

      if (claimedDeviceId == null || claimedDeviceId == deviceId || isStale) {
        transaction.set(
          claimRef,
          <String, dynamic>{
            'deviceId': deviceId,
            'claimedAtMs': claimedDeviceId == deviceId
                ? (data?['claimedAtMs'] as int? ?? nowMs)
                : nowMs,
            'updatedAtMs': nowMs,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );

        return const MainDeviceClaimStatus(
          isActiveOnThisDevice: true,
          isClaimedByAnotherDevice: false,
        );
      }

      return const MainDeviceClaimStatus(
        isActiveOnThisDevice: false,
        isClaimedByAnotherDevice: true,
      );
    });
  }

  Future<void> _releaseMainDeviceClaimIfOwned() async {
    if (!isConfigured) return;
    if (!await _connectivityService.isOnline) return;

    final scopeId = await _resolveScopeId();
    if (scopeId == null || scopeId.isEmpty) return;

    final claimRef = _mainDeviceClaimRef(scopeId);
    final deviceId = await _getOrCreateDeviceId();

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(claimRef);
      final data = snapshot.data();
      final claimedDeviceId = data?['deviceId'] as String?;
      if (claimedDeviceId == deviceId) {
        transaction.delete(claimRef);
      }
    });

    _cachedMainDeviceClaimStatus = const MainDeviceClaimStatus(
      isActiveOnThisDevice: false,
      isClaimedByAnotherDevice: false,
    );
  }
}
