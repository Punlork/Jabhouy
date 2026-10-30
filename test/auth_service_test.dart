import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:jabhouy/app/app.dart';
import 'package:jabhouy/auth/auth.dart';
import 'package:jabhouy_core/jabhouy_core.dart';
import 'package:jabhouy_net/jabhouy_net.dart';
import 'package:jabhouy_ui/jabhouy_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockApiService extends Mock implements ApiService {}

class _MockApiCookies extends Mock implements ApiCookies {}

class _MockConnectivityService extends Mock implements ConnectivityService {}

class _FakeUri extends Fake implements Uri {}

class _MockGoogleSignIn extends Mock implements GoogleSignIn {}

class _MockGoogleAccount extends Mock implements GoogleSignInAccount {}

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
    when(() => apiService.uri('')).thenReturn(Uri.https('example.com'));
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
  group('signInWithGoogle', () {
    late _MockGoogleSignIn google;

    Future<ApiResponse<User>> postSocial() => apiService.post<User>(
          '/auth/sign-in/social',
          body: any(named: 'body'),
          parser: any(named: 'parser'),
          bodyParser: any(named: 'bodyParser'),
          imageFile: any(named: 'imageFile'),
          imageFieldName: any(named: 'imageFieldName'),
          context: any(named: 'context'),
          showSnackBar: any(named: 'showSnackBar'),
        );

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      dotenv.testLoad(fileInput: 'GOOGLE_SERVER_CLIENT_ID=web-client');
      google = _MockGoogleSignIn();
      authService = AuthService(
        apiService,
        connectivityService,
        googleSignIn: google,
      );
      when(() => connectivityService.isOnline).thenAnswer((_) async => true);
      when(
        () => google.initialize(serverClientId: any(named: 'serverClientId')),
      ).thenAnswer((_) async {});
    });

    test('posts the Google ID token and caches the user', () async {
      final account = _MockGoogleAccount();
      when(() => account.authentication)
          .thenReturn(const GoogleSignInAuthentication(idToken: 'id-token'));
      when(() => google.authenticate()).thenAnswer((_) async => account);
      when(postSocial).thenAnswer(
        (_) async => ApiResponse(
          success: true,
          data: const User(id: 'g-1', email: 'a@gmail.com'),
        ),
      );

      final response = await authService.signInWithGoogle();

      expect(response?.data?.id, 'g-1');
      final body = verify(
        () => apiService.post<User>(
          '/auth/sign-in/social',
          body: captureAny(named: 'body'),
          parser: any(named: 'parser'),
          bodyParser: any(named: 'bodyParser'),
          imageFile: any(named: 'imageFile'),
          imageFieldName: any(named: 'imageFieldName'),
          context: any(named: 'context'),
          showSnackBar: any(named: 'showSnackBar'),
        ),
      ).captured.single as Map<String, dynamic>;
      expect(body, {
        'provider': 'google',
        'idToken': {'token': 'id-token'},
      });
      expect((await authService.getCachedUser())?.id, 'g-1');
    });

    test('names a Google user after their Google name and saves it', () async {
      final account = _MockGoogleAccount();
      when(() => account.authentication)
          .thenReturn(const GoogleSignInAuthentication(idToken: 'id-token'));
      when(() => google.authenticate()).thenAnswer((_) async => account);
      when(postSocial).thenAnswer(
        (_) async => ApiResponse(
          success: true,
          data: const User(id: 'g-1', name: 'Dara Sok', email: 'a@gmail.com'),
        ),
      );
      Future<ApiResponse<bool>> postBool(String path) => apiService.post<bool>(
            path,
            body: any(named: 'body'),
            parser: any(named: 'parser'),
            bodyParser: any(named: 'bodyParser'),
            imageFile: any(named: 'imageFile'),
            imageFieldName: any(named: 'imageFieldName'),
            context: any(named: 'context'),
            showSnackBar: any(named: 'showSnackBar'),
          );
      when(() => postBool('/auth/is-username-available')).thenAnswer(
        (_) async => ApiResponse(success: true, data: true),
      );
      when(() => postBool('/auth/update-user')).thenAnswer(
        (_) async => ApiResponse(success: true, data: true),
      );

      final response = await authService.signInWithGoogle();

      expect(response?.data?.username, 'dara_sok');
      expect(response?.data?.name, 'Dara Sok');
      expect((await authService.getCachedUser())?.username, 'dara_sok');
      final sent = verify(
        () => apiService.post<bool>(
          '/auth/update-user',
          body: any(named: 'body'),
          parser: any(named: 'parser'),
          bodyParser: captureAny(named: 'bodyParser'),
          imageFile: any(named: 'imageFile'),
          imageFieldName: any(named: 'imageFieldName'),
          context: any(named: 'context'),
          showSnackBar: any(named: 'showSnackBar'),
        ),
      ).captured.single as Map<String, dynamic> Function();
      expect(sent()['username'], 'dara_sok');
    });

    test('signs in without a Username when none can be saved', () async {
      final account = _MockGoogleAccount();
      when(() => account.authentication)
          .thenReturn(const GoogleSignInAuthentication(idToken: 'id-token'));
      when(() => google.authenticate()).thenAnswer((_) async => account);
      when(postSocial).thenAnswer(
        (_) async => ApiResponse(
          success: true,
          data: const User(id: 'g-1', name: 'Dara Sok', email: 'a@gmail.com'),
        ),
      );
      // Nothing else is stubbed, so the availability check throws.

      final response = await authService.signInWithGoogle();

      expect(response?.success, isTrue);
      expect(response?.data?.username, isNull);
    });

    test('returns null and calls no API when the user cancels', () async {
      when(() => google.authenticate()).thenThrow(
        const GoogleSignInException(code: GoogleSignInExceptionCode.canceled),
      );

      expect(await authService.signInWithGoogle(), isNull);
      verifyNever(postSocial);
    });

    test('throws when Google refuses but reports it as a cancel', () async {
      when(() => google.authenticate()).thenThrow(
        const GoogleSignInException(
          code: GoogleSignInExceptionCode.canceled,
          description: '[16] Account reauth failed.',
        ),
      );

      await expectLater(
        authService.signInWithGoogle(),
        throwsA(isA<GoogleSignInException>()),
      );
      verifyNever(postSocial);
    });

    test('is refused offline before opening Google', () async {
      when(() => connectivityService.isOnline).thenAnswer((_) async => false);

      final response = await authService.signInWithGoogle();

      expect(response?.success, isFalse);
      expect(response?.message, contains('internet'));
      verifyNever(() => google.authenticate());
      verifyNever(postSocial);
    });
  });
  test('usernameSuggestions drops taken names and keeps valid ones', () async {
    when(
      () => apiService.post<bool>(
        '/auth/is-username-available',
        body: any(named: 'body'),
        parser: any(named: 'parser'),
        bodyParser: any(named: 'bodyParser'),
        imageFile: any(named: 'imageFile'),
        imageFieldName: any(named: 'imageFieldName'),
        context: any(named: 'context'),
        showSnackBar: any(named: 'showSnackBar'),
      ),
    ).thenAnswer((invocation) async {
      final body = invocation.namedArguments[#body] as Map<String, dynamic>;
      return ApiResponse(success: true, data: body['username'] != 'dara_sok');
    });

    final suggestions = await authService.usernameSuggestions(
      const User(name: 'Dara Sok', email: 'dara.sok@gmail.com'),
    );

    expect(suggestions, isNotEmpty);
    expect(suggestions.length, lessThanOrEqualTo(3));
    expect(suggestions, isNot(contains('dara_sok')));
    expect(suggestions, contains('dara.sok'));
    expect(suggestions.every(AuthService.isValidUsername), isTrue);
  });
  testWidgets('signout also signs out of Google', (tester) async {
    // signout shows the loading overlay, which needs a real one.
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            GlobalContext.currentContext = context;
            return const SizedBox();
          },
        ),
      ),
    );
    dotenv.testLoad(fileInput: 'GOOGLE_SERVER_CLIENT_ID=web-client');
    final google = _MockGoogleSignIn();
    when(
      () => google.initialize(serverClientId: any(named: 'serverClientId')),
    ).thenAnswer((_) async {});
    when(google.signOut).thenAnswer((_) async {});
    when(() => connectivityService.isOnline).thenAnswer((_) async => true);
    when(
      () => apiService.post<dynamic>(
        '/auth/sign-out',
        body: any(named: 'body'),
        parser: any(named: 'parser'),
        bodyParser: any(named: 'bodyParser'),
        imageFile: any(named: 'imageFile'),
        imageFieldName: any(named: 'imageFieldName'),
        context: any(named: 'context'),
        showSnackBar: any(named: 'showSnackBar'),
      ),
    ).thenAnswer((_) async => ApiResponse(success: true));
    authService = AuthService(
      apiService,
      connectivityService,
      googleSignIn: google,
      flags: const FixedFeatureFlags({Feature.googleSignIn}),
    );

    final response = await authService.signout();

    expect(response.success, isTrue);
    verify(google.signOut).called(1);
  });
}
