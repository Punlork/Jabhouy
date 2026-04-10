import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_app/app/service/database/app_database.dart';
import 'package:my_app/income/income.dart';

class _MockNotificationTrackingBridge extends Mock
    implements NotificationTrackingBridge {}

class _MockFirebaseIncomeSyncService extends Mock
    implements FirebaseIncomeSyncService {}

class _MockNotificationDiagnosticsService extends Mock
    implements NotificationDiagnosticsService {}

void main() {
  late AppDatabase database;
  late _MockNotificationTrackingBridge bridge;
  late _MockFirebaseIncomeSyncService syncService;
  late _MockNotificationDiagnosticsService diagnostics;
  late IncomeService incomeService;

  setUpAll(() {
    registerFallbackValue(
      BankNotificationModel(
        fingerprint: 'fallback',
        packageName: 'com.paygo24.ibank',
        bankApp: BankApp.aba,
        message: 'Fallback',
        receivedAt: DateTime(2026),
        isIncome: true,
      ),
    );
  });

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    bridge = _MockNotificationTrackingBridge();
    syncService = _MockFirebaseIncomeSyncService();
    diagnostics = _MockNotificationDiagnosticsService();
    incomeService = IncomeService(
      database,
      bridge,
      syncService,
      diagnostics,
    );

    when(() => syncService.canAcceptLocalCapture())
        .thenAnswer((_) async => true);
    when(
      () => diagnostics.log(
        source: any(named: 'source'),
        message: any(named: 'message'),
        level: any(named: 'level'),
        metadata: any(named: 'metadata'),
      ),
    ).thenAnswer((_) async {});
  });

  tearDown(() async {
    await database.close();
  });

  test('saveTrackedNotificationMap marks synced notifications after upload',
      () async {
    when(() => syncService.syncNotification(any()))
        .thenAnswer((_) async => true);

    await incomeService.saveTrackedNotificationMap({
      'fingerprint': 'income-1',
      'packageName': 'com.paygo24.ibank',
      'bankKey': 'aba',
      'message': 'Incoming USD 10',
      'receivedAt': DateTime(2026).millisecondsSinceEpoch,
      'isIncome': true,
    });

    final saved = await (database.select(database.bankNotifications)
          ..where((tbl) => tbl.fingerprint.equals('income-1')))
        .getSingle();

    expect(saved.syncStatus, 0);
    verify(() => syncService.syncNotification(any())).called(1);
  });

  test('saveTrackedNotificationMap keeps imported notifications pending',
      () async {
    await incomeService.saveTrackedNotificationMap(
      {
        'fingerprint': 'income-2',
        'packageName': 'com.paygo24.ibank',
        'bankKey': 'aba',
        'message': 'Incoming USD 20',
        'receivedAt': DateTime(2026).millisecondsSinceEpoch,
        'isIncome': true,
      },
      triggerRemoteSync: false,
    );

    final saved = await (database.select(database.bankNotifications)
          ..where((tbl) => tbl.fingerprint.equals('income-2')))
        .getSingle();

    expect(saved.syncStatus, 1);
    verifyNever(() => syncService.syncNotification(any()));
  });
}
