import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:my_app/app/service/database/app_database.dart';
import 'package:my_app/income/income.dart';

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
    this._db,
    this._bridge,
    this._syncService,
    this._diagnostics,
  );

  final AppDatabase _db;
  final NotificationTrackingBridge _bridge;
  final FirebaseIncomeSyncService _syncService;
  final NotificationDiagnosticsService _diagnostics;
  StreamSubscription<Map<String, dynamic>>? _nativeSubscription;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    await _diagnostics.initialize();
    await _diagnostics.log(
      source: 'flutter.income_service',
      message: 'Initializing income service.',
    );

    await importPendingTrackedNotifications();
    await _syncService.initialize(
      onRemotePayload: (payload) => saveTrackedNotificationMap(
        payload,
        triggerRemoteSync: false,
      ),
      loadLocalNotifications: _loadAllNotifications,
    );

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
    _initialized = false;
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
      isBlockedByAnotherMainDevice:
          mainDeviceClaimStatus.isClaimedByAnotherDevice,
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
          message:
              'Dropped pending native notifications because local capture is not allowed on this device.',
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
        message:
            'Imported pending native notifications from Android shared storage.',
        metadata: {
          'count': pending.length,
        },
      );
    }
  }

  Future<bool> seedDemoNotifications() async {
    if (!await _syncService.canAcceptLocalCapture()) {
      await _diagnostics.log(
        source: 'flutter.income_service',
        message:
            'Blocked demo notification seed because local capture is not allowed.',
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
        'fingerprint':
            'demo-chip-${now.subtract(const Duration(hours: 3)).millisecondsSinceEpoch}',
        'packageName': 'com.chipmongbank.mobileappproduction',
        'bankKey': 'chip_mong',
        'title': 'Incoming transfer',
        'message': 'Incoming transfer USD 180.50 to your account.',
        'amount': 180.5,
        'currency': 'USD',
        'isIncome': true,
        'receivedAt':
            now.subtract(const Duration(hours: 3)).millisecondsSinceEpoch,
        'source': 'demo',
      },
      {
        'fingerprint':
            'demo-acleda-${now.subtract(const Duration(days: 1)).millisecondsSinceEpoch}',
        'packageName': 'com.domain.acledabankqr',
        'bankKey': 'acleda',
        'title': 'Transfer out',
        'message': 'Transfer out KHR 40,000 from your account.',
        'amount': 40000,
        'currency': 'KHR',
        'isIncome': false,
        'receivedAt':
            now.subtract(const Duration(days: 1)).millisecondsSinceEpoch,
        'source': 'demo',
      },
    ];

    for (final sample in samples) {
      await saveTrackedNotificationMap(sample);
    }

    await _diagnostics.log(
      source: 'flutter.income_service',
      message: 'Seeded fallback demo notifications directly in Flutter.',
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
    final query = _db.select(_db.bankNotifications);

    if (searchQuery.isNotEmpty) {
      query.where(
        (tbl) =>
            tbl.message.contains(searchQuery) |
            tbl.bankKey.contains(searchQuery) |
            tbl.packageName.contains(searchQuery) |
            tbl.title.contains(searchQuery),
      );
    }

    if (fromDate != null) {
      query.where((tbl) => tbl.receivedAt.isBiggerOrEqualValue(fromDate));
    }

    if (toDate != null) {
      final endOfDay = DateTime(
        toDate.year,
        toDate.month,
        toDate.day,
        23,
        59,
        59,
        999,
      );
      query.where((tbl) => tbl.receivedAt.isSmallerOrEqualValue(endOfDay));
    }

    if (bankFilter != null && bankFilter != BankApp.unknown) {
      query.where((tbl) => tbl.bankKey.equals(bankFilter.key));
    }

    switch (recordFilter) {
      case NotificationRecordFilter.income:
        query.where((tbl) => tbl.isIncome.equals(true));
      case NotificationRecordFilter.expense:
        query.where((tbl) => tbl.isIncome.equals(false));
      case NotificationRecordFilter.all:
        break;
    }

    query.orderBy([
      (tbl) => OrderingTerm(
            expression: tbl.receivedAt,
            mode: OrderingMode.desc,
          ),
      (tbl) => OrderingTerm(
            expression: tbl.id,
            mode: OrderingMode.desc,
          ),
    ]);

    return query.watch().map(
          (rows) => rows.map(_mapRow).toList(growable: false),
        );
  }

  BankNotificationModel _mapRow(BankNotification row) {
    return BankNotificationModel(
      id: row.id,
      fingerprint: row.fingerprint,
      packageName: row.packageName,
      bankApp: BankApp.fromKey(row.bankKey),
      title: row.title,
      message: row.message,
      rawPayload: row.rawPayload,
      amount: row.amount,
      currency: row.currency,
      isIncome: row.isIncome,
      receivedAt: row.receivedAt,
      source: row.source,
      createdAt: row.createdAt,
    );
  }

  Future<List<BankNotificationModel>> _loadAllNotifications() async {
    final rows = await (_db.select(_db.bankNotifications)
          ..orderBy([
            (tbl) => OrderingTerm(
                  expression: tbl.receivedAt,
                  mode: OrderingMode.desc,
                ),
          ]))
        .get();

    return rows.map(_mapRow).toList(growable: false);
  }

  Future<void> saveTrackedNotificationMap(
    Map<String, dynamic> payload, {
    bool triggerRemoteSync = true,
  }) async {
    final canAcceptLocal = await _syncService.canAcceptLocalCapture();
    if (triggerRemoteSync && !canAcceptLocal) {
      await _diagnostics.log(
        source: 'flutter.income_service',
        message:
            'Ignored tracked notification because local capture is blocked on this device.',
        level: 'warning',
        metadata: {
          'packageName': payload['packageName'],
          'fingerprint': payload['fingerprint'],
        },
      );
      return;
    }

    final model = BankNotificationModel.fromNativeMap(payload);
    final existing = await (_db.select(_db.bankNotifications)
          ..where((tbl) => tbl.fingerprint.equals(model.fingerprint)))
        .getSingleOrNull();
    if (existing == null) {
      await _db.into(_db.bankNotifications).insert(
            BankNotificationsCompanion.insert(
              fingerprint: model.fingerprint,
              packageName: model.packageName,
              bankKey: model.bankApp.key,
              title: Value(model.title),
              message: model.message,
              rawPayload: Value(
                model.rawPayload ?? jsonEncode(payload),
              ),
              amount: Value(model.amount),
              currency: Value(model.currency),
              isIncome: Value(model.isIncome),
              receivedAt: model.receivedAt,
              source: Value(model.source),
              createdAt: Value(model.createdAt),
            ),
          );
    } else {
      await (_db.update(_db.bankNotifications)
            ..where((tbl) => tbl.id.equals(existing.id)))
          .write(
        BankNotificationsCompanion(
          packageName: Value(model.packageName),
          bankKey: Value(model.bankApp.key),
          title: Value(model.title),
          message: Value(model.message),
          rawPayload: Value(
            model.rawPayload ?? jsonEncode(payload),
          ),
          amount: Value(model.amount),
          currency: Value(model.currency),
          isIncome: Value(model.isIncome),
          receivedAt: Value(model.receivedAt),
          source: Value(model.source),
          createdAt: Value(model.createdAt),
        ),
      );
    }

    await _diagnostics.log(
      source: 'flutter.income_service',
      message: existing == null
          ? 'Stored new notification in Drift.'
          : 'Updated existing notification in Drift.',
      metadata: {
        'fingerprint': model.fingerprint,
        'packageName': model.packageName,
        'bankKey': model.bankApp.key,
        'isIncome': model.isIncome,
        'source': model.source,
      },
    );

    if (triggerRemoteSync && existing == null) {
      await _syncService.syncNotification(model);
    }
  }
}
