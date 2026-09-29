import 'package:flutter_test/flutter_test.dart';
import 'package:jabhouy/app/app.dart';
import 'package:jabhouy/auth/auth.dart';
import 'package:jabhouy_net/jabhouy_net.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockApiService extends Mock implements ApiService {}

class _MockApiCookies extends Mock implements ApiCookies {}

class _MockConnectivityService extends Mock implements ConnectivityService {}

class _FakeUri extends Fake implements Uri {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(_FakeUri());
  });

  late _MockApiService apiService;
  late _MockApiCookies apiCookies;
  late _MockConnectivityService connectivityService;
  late AuthService authService;

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'cached_auth_user': '{"id":"user-1","name":"Offline User"}',
    });

    if (getIt.isRegistered<ApiService>()) {
      getIt.unregister<ApiService>();
    }

    apiService = _MockApiService();
    apiCookies = _MockApiCookies();
    connectivityService = _MockConnectivityService();
    authService = AuthService(apiService, connectivityService);

    when(() => apiService.cookies).thenReturn(apiCookies);
    when(() => apiService.baseUrl).thenReturn('example.com');
    when(() => apiCookies.getCookieHeader(any())).thenReturn(null);
  });

  tearDown(() async {
    if (getIt.isRegistered<ApiService>()) {
      getIt.unregister<ApiService>();
    }
  });

  test('bootstrapSession restores cached user while offline without cookies',
      () async {
    getIt.registerSingleton<ApiService>(apiService);
    when(() => connectivityService.isOnline).thenAnswer((_) async => false);

    final result = await authService.bootstrapSession();

    expect(result.response.success, isTrue);
    expect(result.response.data?.id, 'user-1');
    expect(result.usedCachedSession, isTrue);
  });

  group('with a saved session online', () {
    void stubSession(ApiResponse<User?> response) {
      when(
        () => apiService.get<User?>(
          any(),
          parser: any(named: 'parser'),
          queryParameters: any(named: 'queryParameters'),
          showSnackBar: any(named: 'showSnackBar'),
        ),
      ).thenAnswer((_) async => response);
    }

    setUp(() {
      getIt.registerSingleton<ApiService>(apiService);
      when(() => apiCookies.getCookieHeader(any())).thenReturn('session=1');
      when(() => connectivityService.isOnline).thenAnswer((_) async => true);
    });

    test('bootstrapSession opens on it without waiting for the server',
        () async {
      final result = await authService.bootstrapSession();

      expect(result.response.data?.id, 'user-1');
      expect(result.usedCachedSession, isTrue);
      verifyNever(
        () => apiService.get<User?>(
          any(),
          parser: any(named: 'parser'),
          queryParameters: any(named: 'queryParameters'),
          showSnackBar: any(named: 'showSnackBar'),
        ),
      );
    });

    test('revalidateSession clears a session the server rejects', () async {
      stubSession(
        ApiResponse(success: false, message: 'Unauthorized', statusCode: 401),
      );

      final response = await authService.revalidateSession();

      expect(response?.success, isFalse);
      expect(await authService.getCachedUser(), isNull);
    });

    test('revalidateSession keeps the session when the server is unreachable',
        () async {
      stubSession(ApiResponse(success: false, message: 'Network error'));

      final response = await authService.revalidateSession();

      expect(response, isNull);
      expect((await authService.getCachedUser())?.id, 'user-1');
    });
  });
}
