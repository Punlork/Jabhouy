import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:my_app/app/app.dart';
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
    this._apiService,
    this._db,
    this._bridge,
    this._syncService,
    this._diagnostics,
  );

  final ApiService _apiService;
  final AppDatabase _db;
  final NotificationTrackingBridge _bridge;
  final FirebaseIncomeSyncService _syncService;
  final NotificationDiagnosticsService _diagnostics;
  StreamSubscription<Map<String, dynamic>>? _nativeSubscription;
  bool _initialized = false;
  DateTime? _lastRemotePullAt;

  static const _notificationSyncStatusSynced = 0;
  static const _notificationSyncStatusPending = 1;
  static const _notificationSyncStatusError = 2;

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

  Future<int> pullRemoteNotifications({bool force = false}) async {
    final now = DateTime.now();
    if (!force && _lastRemotePullAt != null) {
      final elapsed = now.difference(_lastRemotePullAt!);
      if (elapsed < const Duration(seconds: 20)) {
        return 0;
      }
    }
    _lastRemotePullAt = now;

    try {
      final response = await _apiService.get<List<BankNotificationModel>>(
        '/notifications',
        showSnackBar: false,
        parser: _parseNotificationsResponse,
      );
      if (!response.success || response.data == null) {
        await _diagnostics.log(
          source: 'flutter.income_service',
          message: 'Failed to pull remote notifications list from backend.',
          level: 'warning',
          metadata: {
            'message': response.message,
          },
        );
        return 0;
      }

      var upsertCount = 0;
      for (final model in response.data!) {
        if (await _upsertNotificationModel(model, triggerRemoteSync: false)) {
          upsertCount++;
        }
      }
      final repairedCount = await _backfillStoredNotificationMetadata();

      await _diagnostics.log(
        source: 'flutter.income_service',
        message: 'Pulled remote notifications from backend.',
        metadata: {
          'receivedCount': response.data!.length,
          'upsertedCount': upsertCount,
          'repairedCount': repairedCount,
        },
      );
      return upsertCount + repairedCount;
    } catch (error) {
      await _diagnostics.log(
        source: 'flutter.income_service',
        message: 'Unhandled error while pulling remote notifications.',
        level: 'error',
        metadata: {
          'error': error.toString(),
        },
      );
      return 0;
    }
  }

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

  Future<List<BankNotificationModel>> _loadPendingNotifications() async {
    final rows = await (_db.select(_db.bankNotifications)
          ..where(
            (tbl) =>
                tbl.syncStatus.equals(_notificationSyncStatusPending) |
                tbl.syncStatus.equals(_notificationSyncStatusError),
          )
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
    final upserted = await _upsertNotificationModel(
      model,
      triggerRemoteSync: triggerRemoteSync && canAcceptLocal,
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
      final didSync = await _syncService.syncNotification(model);
      await _updateNotificationSyncStatus(
        model.fingerprint,
        didSync ? _notificationSyncStatusSynced : _notificationSyncStatusError,
      );
    }
  }

  Future<void> _updateNotificationSyncStatus(
    String fingerprint,
    int syncStatus,
  ) async {
    await (_db.update(_db.bankNotifications)..where((tbl) => tbl.fingerprint.equals(fingerprint))).write(
      BankNotificationsCompanion(
        syncStatus: Value(syncStatus),
      ),
    );
  }

  Future<bool> _upsertNotificationModel(
    BankNotificationModel model, {
    required bool triggerRemoteSync,
    String? rawPayloadOverride,
  }) async {
    final existing = await (_db.select(_db.bankNotifications)
          ..where((tbl) => tbl.fingerprint.equals(model.fingerprint)))
        .getSingleOrNull();
    final syncStatus = triggerRemoteSync ? _notificationSyncStatusPending : _notificationSyncStatusSynced;

    if (existing == null) {
      await _db.into(_db.bankNotifications).insert(
            BankNotificationsCompanion.insert(
              fingerprint: model.fingerprint,
              packageName: model.packageName,
              bankKey: model.bankApp.key,
              title: Value(model.title),
              message: model.message,
              rawPayload: Value(rawPayloadOverride ?? model.rawPayload),
              amount: Value(model.amount),
              currency: Value(model.currency),
              isIncome: Value(model.isIncome),
              receivedAt: model.receivedAt,
              source: Value(model.source),
              syncStatus: Value(syncStatus),
              createdAt: Value(model.createdAt),
            ),
          );
      return true;
    }

    await (_db.update(_db.bankNotifications)..where((tbl) => tbl.id.equals(existing.id))).write(
      BankNotificationsCompanion(
        packageName: Value(model.packageName),
        bankKey: Value(model.bankApp.key),
        title: Value(model.title),
        message: Value(model.message),
        rawPayload: Value(rawPayloadOverride ?? model.rawPayload),
        amount: Value(model.amount),
        currency: Value(model.currency),
        isIncome: Value(model.isIncome),
        receivedAt: Value(model.receivedAt),
        source: Value(model.source),
        syncStatus: Value(existing.syncStatus),
        createdAt: Value(model.createdAt),
      ),
    );
    return false;
  }

  List<BankNotificationModel> _parseNotificationsResponse(dynamic payload) {
    dynamic data = payload;

    if (data is Map<String, dynamic>) {
      data = data['data'] ?? data['notifications'] ?? data['items'] ?? data['results'];
    }

    if (data is! List) return const [];

    return data
        .whereType<Object?>()
        .map((entry) {
          Map<String, dynamic>? normalized;

          if (entry is Map<String, dynamic>) {
            normalized = BankNotificationModel.fromJSON(entry);
          } else if (entry is Map) {
            normalized = BankNotificationModel.fromJSON(
              Map<String, dynamic>.from(entry),
            );
          }

          if (normalized == null) return null;

          return BankNotificationModel.fromNativeMap(normalized);
        })
        .whereType<BankNotificationModel>()
        .toList(growable: false);
  }

  Future<int> _backfillStoredNotificationMetadata() async {
    final rows = await (_db.select(_db.bankNotifications)
          ..where(
            (tbl) => tbl.bankKey.equals(BankApp.unknown.key) | tbl.amount.isNull(),
          ))
        .get();

    if (rows.isEmpty) return 0;

    var repaired = 0;
    for (final row in rows) {
      final candidate = BankNotificationModel.fromNativeMap({
        'fingerprint': row.fingerprint,
        'packageName': row.packageName,
        'title': row.title,
        'message': row.message,
        'receivedAt': row.receivedAt.millisecondsSinceEpoch,
        'source': row.source,
        'createdAt': row.createdAt.toIso8601String(),
      });

      final shouldUpdateBank = row.bankKey == BankApp.unknown.key && candidate.bankApp != BankApp.unknown;
      final shouldUpdateAmount = row.amount == null && candidate.amount != null;
      final shouldUpdateCurrency = shouldUpdateAmount &&
          row.currency == 'USD' &&
          candidate.currency.isNotEmpty &&
          candidate.currency != row.currency;

      if (!shouldUpdateBank && !shouldUpdateAmount && !shouldUpdateCurrency) {
        continue;
      }

      await (_db.update(_db.bankNotifications)..where((tbl) => tbl.id.equals(row.id))).write(
        BankNotificationsCompanion(
          bankKey: shouldUpdateBank ? Value(candidate.bankApp.key) : const Value.absent(),
          amount: shouldUpdateAmount ? Value(candidate.amount) : const Value.absent(),
          currency: shouldUpdateCurrency ? Value(candidate.currency) : const Value.absent(),
        ),
      );
      repaired++;
    }

    return repaired;
  }
}
