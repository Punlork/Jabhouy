import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_app/app/app.dart';
import 'package:my_app/auth/auth.dart';
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
}
