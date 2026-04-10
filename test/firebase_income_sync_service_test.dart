import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_app/app/app.dart';
import 'package:my_app/auth/auth.dart';
import 'package:my_app/income/income.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockConnectivityService extends Mock implements ConnectivityService {}

class _MockAuthService extends Mock implements AuthService {}

class _MockFcmService extends Mock implements FcmService {}

class _MockNotificationDiagnosticsService extends Mock
    implements NotificationDiagnosticsService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockConnectivityService connectivityService;
  late _MockAuthService authService;
  late _MockFcmService fcmService;
  late _MockNotificationDiagnosticsService diagnosticsService;
  late FirebaseIncomeSyncService syncService;

  final model = BankNotificationModel(
    fingerprint: 'fp-1',
    packageName: 'com.paygo24.ibank',
    bankApp: BankApp.aba,
    message: 'Incoming USD 10',
    receivedAt: DateTime(2026),
    isIncome: true,
  );

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'deviceRole': 'main',
    });

    connectivityService = _MockConnectivityService();
    authService = _MockAuthService();
    fcmService = _MockFcmService();
    diagnosticsService = _MockNotificationDiagnosticsService();
    syncService = FirebaseIncomeSyncService(
      connectivityService,
      authService,
      fcmService,
      diagnosticsService,
    );

    when(() => connectivityService.isOnline).thenAnswer((_) async => true);
    when(() => connectivityService.connectivityStream)
        .thenAnswer((_) => const Stream<bool>.empty());
    when(() => authService.getCachedUser())
        .thenAnswer((_) async => const User(id: 'scope-1'));
    when(
      () => diagnosticsService.log(
        source: any(named: 'source'),
        message: any(named: 'message'),
        level: any(named: 'level'),
        metadata: any(named: 'metadata'),
      ),
    ).thenAnswer((_) async {});
  });

  test('coalesces concurrent sync requests for the same fingerprint', () async {
    final completer = Completer<ApiResponse<Map<String, dynamic>>>();
    when(
      () => fcmService.sendTestNotification(
        title: any(named: 'title'),
        body: any(named: 'body'),
        data: any(named: 'data'),
      ),
    ).thenAnswer((_) => completer.future);

    final first = syncService.syncNotification(model);
    final second = syncService.syncNotification(model);

    completer.complete(
      ApiResponse(
        success: true,
        data: {
          'attempted': 1,
          'succeeded': 1,
          'failed': 0,
        },
      ),
    );

    expect(await first, isTrue);
    expect(await second, isTrue);
    verify(
      () => fcmService.sendTestNotification(
        title: any(named: 'title'),
        body: any(named: 'body'),
        data: any(named: 'data'),
      ),
    ).called(1);
  });

  test('skips re-sending a fingerprint that already synced successfully',
      () async {
    when(
      () => fcmService.sendTestNotification(
        title: any(named: 'title'),
        body: any(named: 'body'),
        data: any(named: 'data'),
      ),
    ).thenAnswer(
      (_) async => ApiResponse(
        success: true,
        data: {
          'attempted': 1,
          'succeeded': 1,
          'failed': 0,
        },
      ),
    );

    expect(await syncService.syncNotification(model), isTrue);
    expect(await syncService.syncNotification(model), isTrue);

    verify(
      () => fcmService.sendTestNotification(
        title: any(named: 'title'),
        body: any(named: 'body'),
        data: any(named: 'data'),
      ),
    ).called(1);
  });
}
