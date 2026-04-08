import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_app/app/app.dart';
import 'package:my_app/app/service/database/app_database.dart';
import 'package:my_app/auth/auth.dart';
import 'package:my_app/income/income.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockApiService extends Mock implements ApiService {}

class _MockApiCookies extends Mock implements ApiCookies {}

class _MockConnectivityService extends Mock implements ConnectivityService {}

class _MockFirebaseIncomeSyncService extends Mock
    implements FirebaseIncomeSyncService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const methodChannel = MethodChannel('jabhouy/notification_tracking/methods');

  late AppDatabase database;
  late _MockApiService apiService;
  late _MockApiCookies apiCookies;
  late AuthService authService;
  late _MockFirebaseIncomeSyncService incomeSyncService;
  late NotificationTrackingBridge notificationTrackingBridge;
  late NotificationDiagnosticsService diagnosticsService;
  late SessionCleanupService sessionCleanupService;

  setUp(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      methodChannel,
      (call) async {
        if (call.method == 'clearDiagnosticsLogs') {
          return null;
        }
        return null;
      },
    );

    SharedPreferences.setMockInitialValues({
      'cached_auth_user': '{"id":"user-1"}',
      'pending_notifications': '[{"fingerprint":"abc"}]',
      'uploaded_notification_fingerprints': '["abc"]',
      'cookies': '{"example.com":{"session":"cookie"}}',
      'deviceRole': 'main',
      'income_sync_scope_id': 'scope-1',
    });

    database = AppDatabase.forTesting(NativeDatabase.memory());
    apiService = _MockApiService();
    apiCookies = _MockApiCookies();
    authService = AuthService(apiService, _MockConnectivityService());
    incomeSyncService = _MockFirebaseIncomeSyncService();
    notificationTrackingBridge = NotificationTrackingBridge();
    diagnosticsService =
        NotificationDiagnosticsService(notificationTrackingBridge);

    when(() => apiService.cookies).thenReturn(apiCookies);
    when(() => apiCookies.clearCookies(domain: any(named: 'domain')))
        .thenAnswer((_) async {});
    when(() => incomeSyncService.clearPersistedSessionState())
        .thenAnswer((_) async {});

    await database.into(database.customers).insert(
          CustomersCompanion.insert(id: const Value(1), name: 'Customer 1'),
        );
    await database.into(database.categories).insert(
          CategoriesCompanion.insert(id: const Value(1), name: 'Category 1'),
        );
    await database.into(database.shopItems).insert(
          ShopItemsCompanion.insert(id: const Value(1), name: 'Shop Item 1'),
        );
    await database.into(database.loaners).insert(
          LoanersCompanion.insert(
            id: const Value(1),
            amount: 10,
            createdAt: DateTime(2026),
          ),
        );
    await database.into(database.bankNotifications).insert(
          BankNotificationsCompanion.insert(
            fingerprint: 'fingerprint-1',
            packageName: 'com.paygo24.ibank',
            bankKey: 'aba',
            message: 'Incoming USD 10',
            receivedAt: DateTime(2026),
          ),
        );

    sessionCleanupService = SessionCleanupService(
      apiService: apiService,
      authService: authService,
      database: database,
      incomeSyncService: incomeSyncService,
      notificationTrackingBridge: notificationTrackingBridge,
      notificationDiagnosticsService: diagnosticsService,
    );
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(methodChannel, null);
    await database.close();
  });

  test(
    'clearSignedInUserData clears persisted user session and local data',
    () async {
      await sessionCleanupService.clearSignedInUserData();

      final sharedPreferences = await SharedPreferences.getInstance();

      expect(sharedPreferences.getString('cached_auth_user'), isNull);
      expect(sharedPreferences.getString('pending_notifications'), isNull);
      expect(
        sharedPreferences.getString('uploaded_notification_fingerprints'),
        isNull,
      );

      expect(await database.select(database.customers).get(), isEmpty);
      expect(await database.select(database.categories).get(), isEmpty);
      expect(await database.select(database.shopItems).get(), isEmpty);
      expect(await database.select(database.loaners).get(), isEmpty);
      expect(await database.select(database.bankNotifications).get(), isEmpty);

      verify(() => incomeSyncService.clearPersistedSessionState()).called(1);
      verify(() => apiCookies.clearCookies()).called(1);
    },
  );
}
