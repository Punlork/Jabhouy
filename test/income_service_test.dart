import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jabhouy/app/app.dart';
import 'package:jabhouy/income/income.dart';
import 'package:jabhouy_core/jabhouy_core.dart';
import 'package:jabhouy_sync/jabhouy_sync.dart';
import 'package:mocktail/mocktail.dart';

class _MockIncomeApi extends Mock implements IncomeApi {}

class _MockNotificationTrackingBridge extends Mock
    implements NotificationTrackingBridge {}

class _MockFirebaseIncomeSyncService extends Mock
    implements FirebaseIncomeSyncService {}

class _MockNotificationDiagnosticsService extends Mock
    implements NotificationDiagnosticsService {}

void main() {
  late _MockIncomeApi api;
  late AppDatabase database;
  late IncomeDao dao;
  late SyncEngine engine;
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
    api = _MockIncomeApi();
    database = AppDatabase(NativeDatabase.memory());
    dao = IncomeDao(database);
    bridge = _MockNotificationTrackingBridge();
    syncService = _MockFirebaseIncomeSyncService();
    diagnostics = _MockNotificationDiagnosticsService();

    // The whole chain, not a mocked repository: these two tests are the
    // record of what income must keep doing across the slice, so they
    // run through the real dao, engine and adapter.
    engine = SyncEngine(
      database: database,
      transport: AppSyncTransport([
        IncomeSyncAdapter(
          dao,
          syncService.syncNotification,
          syncService.canAcceptLocalCapture,
        ),
      ]),
    );
    final repository = DefaultIncomeRepository(dao, api, engine);
    incomeService = IncomeService(
      repository,
      PullRemoteNotificationsUseCase(repository, diagnostics),
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

    expect(saved.syncStatus, SyncStatus.synced);
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

    expect(saved.syncStatus, SyncStatus.pending);
    verifyNever(() => syncService.syncNotification(any()));
  });
}
