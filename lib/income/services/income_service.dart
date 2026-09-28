import 'dart:async';
import 'dart:convert';

import 'package:async/async.dart' show AsyncMemoizer;
import 'package:jabhouy/income/income.dart';
import 'package:jabhouy_core/jabhouy_core.dart';

class NotificationTrackingStatus {
  const NotificationTrackingStatus({
    required this.isSupported,
    required this.isAccessEnabled,
    required this.canCaptureLocally,
    required this.isBlockedByAnotherMainDevice,
  });

  final bool isSupported;
  final bool isAccessEnabled;
  final bool canCaptureLocally;
  final bool isBlockedByAnotherMainDevice;
}

class IncomeService {
  IncomeService(
    this._repository,
    this._pullRemote,
    this._bridge,
    this._syncService,
    this._diagnostics,
  );

  /// What is left here after the slice: the Android bridge, the Firebase
  /// session, device-role gating and the demo seed. Everything that was
  /// a Drift statement or an HTTP call moved to `data/`, and the pull
  /// policy moved to `logic/`.
  final IncomeRepository _repository;
  final PullRemoteNotificationsUseCase _pullRemote;
  final NotificationTrackingBridge _bridge;
  final FirebaseIncomeSyncService _syncService;
  final NotificationDiagnosticsService _diagnostics;
  StreamSubscription<Map<String, dynamic>>? _nativeSubscription;
  // A second caller waits for the first one's setup instead of returning
  // before it finishes, which a bool set up front could not do.
  var _initialization = AsyncMemoizer<void>();

  Future<void> initialize() => _initialization.runOnce(_initialize);

  Future<void> _initialize() async {
    await _diagnostics.initialize();
    await _diagnostics.log(
      source: 'flutter.income_service',
      message: 'Initializing income service.',
    );

    await importPendingTrackedNotifications();
    await _syncService.initialize(
      loadLocalNotifications: _loadPendingNotifications,
      updateNotificationSyncStatus: _updateNotificationSyncStatus,
    );
    await pullRemoteNotifications(force: true);

    _nativeSubscription = _bridge.notificationStream.listen((payload) async {
      await _diagnostics.log(
        source: 'flutter.income_service',
        message: 'Received native notification event from Android bridge.',
        metadata: {
          'packageName': payload['packageName'],
          'fingerprint': payload['fingerprint'],
        },
      );
      await saveTrackedNotificationMap(payload);
    });
  }

  Future<void> dispose() async {
    await _nativeSubscription?.cancel();
    await _syncService.dispose();
    _initialization = AsyncMemoizer<void>();
  }

  Future<NotificationTrackingStatus> getTrackingStatus() async {
    final mainDeviceClaimStatus = await _syncService.getMainDeviceClaimStatus();
    final isAccessEnabled = await _bridge.isNotificationAccessEnabled();

    await _diagnostics.log(
      source: 'flutter.income_service',
      message: 'Fetched notification tracking status.',
      metadata: {
        'isSupported': _bridge.isSupported,
        'isAccessEnabled': isAccessEnabled,
        'canCaptureLocally': mainDeviceClaimStatus.isActiveOnThisDevice,
        'blockedByAnotherMain': mainDeviceClaimStatus.isClaimedByAnotherDevice,
      },
    );

    return NotificationTrackingStatus(
      isSupported: _bridge.isSupported,
      isAccessEnabled: isAccessEnabled,
      canCaptureLocally: mainDeviceClaimStatus.isActiveOnThisDevice,
      isBlockedByAnotherMainDevice: mainDeviceClaimStatus.isClaimedByAnotherDevice,
    );
  }

  Future<void> openNotificationAccessSettings() {
    unawaited(
      _diagnostics.log(
        source: 'flutter.income_service',
        message: 'Opening Android notification access settings.',
      ),
    );
    return _bridge.openNotificationAccessSettings();
  }

  Future<void> importPendingTrackedNotifications() async {
    final pending = await _bridge.drainPendingTrackedNotifications();
    final canAcceptLocalCapture = await _syncService.canAcceptLocalCapture();

    if (!canAcceptLocalCapture) {
      if (pending.isNotEmpty) {
        await _diagnostics.log(
          source: 'flutter.income_service',
          message: 'Dropped pending native notifications because local capture is not allowed on this device.',
          level: 'warning',
          metadata: {
            'count': pending.length,
          },
        );
      }
      return;
    }

    for (final item in pending) {
      await saveTrackedNotificationMap(item, triggerRemoteSync: false);
    }

    if (pending.isNotEmpty) {
      await _diagnostics.log(
        source: 'flutter.income_service',
        message: 'Imported pending native notifications from Android shared storage.',
        metadata: {
          'count': pending.length,
        },
      );
    }
  }

  Future<int> pullRemoteNotifications({bool force = false}) =>
      _pullRemote(force: force);

  Future<bool> seedDemoNotifications() async {
    if (!await _syncService.canAcceptLocalCapture()) {
      await _diagnostics.log(
        source: 'flutter.income_service',
        message: 'Blocked demo notification seed because local capture is not allowed.',
        level: 'warning',
      );
      return false;
    }

    if (_bridge.isSupported) {
      await _bridge.pushDemoNotifications();
      await _diagnostics.log(
        source: 'flutter.income_service',
        message: 'Queued demo notifications through the Android bridge.',
      );
      return true;
    }

    final now = DateTime.now();
    final samples = [
      {
        'fingerprint': 'demo-aba-${now.millisecondsSinceEpoch}',
        'packageName': 'com.paygo24.ibank',
        'bankKey': 'aba',
        'title': 'Money received',
        'message': 'You received USD 245.00 from customer payment.',
        'amount': 245.0,
        'currency': 'USD',
        'isIncome': true,
        'receivedAt': now.millisecondsSinceEpoch,
        'source': 'demo',
      },
      {
        'fingerprint': 'demo-chip-${now.subtract(const Duration(hours: 3)).millisecondsSinceEpoch}',
        'packageName': 'com.chipmongbank.mobileappproduction',
        'bankKey': 'chip_mong',
        'title': 'Incoming transfer',
        'message': 'Incoming transfer USD 180.50 to your account.',
        'amount': 180.5,
        'currency': 'USD',
        'isIncome': true,
        'receivedAt': now.subtract(const Duration(hours: 3)).millisecondsSinceEpoch,
        'source': 'demo',
      },
      {
        'fingerprint': 'demo-acleda-${now.subtract(const Duration(days: 1)).millisecondsSinceEpoch}',
        'packageName': 'com.domain.acledabankqr',
        'bankKey': 'acleda',
        'title': 'Transfer out',
        'message': 'Transfer out KHR 40,000 from your account.',
        'amount': 40000,
        'currency': 'KHR',
        'isIncome': false,
        'receivedAt': now.subtract(const Duration(days: 1)).millisecondsSinceEpoch,
        'source': 'demo',
      },
    ];

    for (final sample in samples) {
      await saveTrackedNotificationMap(sample);
    }

    await _diagnostics.log(
      source: 'flutter.income_service',
      message: 'Seeded demo notifications locally and pushed them through backend test notifications.',
      metadata: {
        'count': samples.length,
      },
    );
    return true;
  }

  Stream<List<BankNotificationModel>> watchNotifications({
    String searchQuery = '',
    DateTime? fromDate,
    DateTime? toDate,
    BankApp? bankFilter,
    NotificationRecordFilter recordFilter = NotificationRecordFilter.all,
  }) {
    return _repository.watchNotifications(
      searchQuery: searchQuery,
      fromDate: fromDate,
      toDate: toDate,
      bankFilter: bankFilter,
      recordFilter: recordFilter,
    );
  }

  Future<List<BankNotificationModel>> _loadPendingNotifications() =>
      _repository.pendingNotifications();

  Future<void> saveTrackedNotificationMap(
    Map<String, dynamic> payload, {
    bool triggerRemoteSync = true,
  }) async {
    final canAcceptLocal = await _syncService.canAcceptLocalCapture();
    if (triggerRemoteSync && !canAcceptLocal) {
      await _diagnostics.log(
        source: 'flutter.income_service',
        message: 'Ignored tracked notification because local capture is blocked on this device.',
        level: 'warning',
        metadata: {
          'packageName': payload['packageName'],
          'fingerprint': payload['fingerprint'],
        },
      );
      return;
    }

    final model = BankNotificationModel.fromNativeMap(payload);
    final upserted = await _repository.store(
      model,
      rawPayloadOverride: model.rawPayload ?? jsonEncode(payload),
    );

    await _diagnostics.log(
      source: 'flutter.income_service',
      message: upserted ? 'Stored new notification in Drift.' : 'Updated existing notification in Drift.',
      metadata: {
        'fingerprint': model.fingerprint,
        'packageName': model.packageName,
        'bankKey': model.bankApp.key,
        'isIncome': model.isIncome,
        'source': model.source,
      },
    );

    if (triggerRemoteSync && canAcceptLocal && upserted) {
      // Queue, then drain. The upload used to happen inline here, so a
      // notification that arrived while the network was down was pushed
      // once, marked failed, and left for the next connectivity change to
      // replay with no backoff. It is now a job like any other.
      await _repository.enqueueUpload(model);
      await _repository.drainUploads();
    }
  }

  Future<void> _updateNotificationSyncStatus(
    String fingerprint,
    SyncStatus syncStatus,
  ) =>
      _repository.updateSyncStatus(fingerprint, syncStatus);
}
