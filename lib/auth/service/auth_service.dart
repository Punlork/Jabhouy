// ignore_for_file: avoid_dynamic_calls

import 'dart:convert';

import 'package:my_app/app/app.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthBootstrapResult {
  const AuthBootstrapResult({
    required this.response,
    required this.usedCachedSession,
  });

  final ApiResponse<User?> response;
  final bool usedCachedSession;
}

class AuthService extends BaseService {
  factory AuthService(
    ApiService apiService,
    ConnectivityService connectivityService,
  ) =>
      AuthService._(
        apiService,
        connectivityService,
      );

  AuthService._(super.apiService, this._connectivityService);

  static const _cachedUserKey = 'cached_auth_user';

  final ConnectivityService _connectivityService;

  @override
  String get basePath => '/auth';

  Future<ApiResponse<User?>> getSession() async {
    return get(
      '/get-session',
      parser: (value) => value != null
          ? User.fromJson(
              value['user'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  Future<User?> getCachedUser() async {
    final sharedPreferences = await SharedPreferences.getInstance();
    final cached = sharedPreferences.getString(_cachedUserKey);
    if (cached == null) {
      return null;
    }

    try {
      return User.fromJson(jsonDecode(cached) as Map<String, dynamic>);
    } catch (_) {
      await clearCachedSession();
      return null;
    }
  }

  Future<void> cacheUser(User user) async {
    final sharedPreferences = await SharedPreferences.getInstance();
    await sharedPreferences.setString(
      _cachedUserKey,
      jsonEncode(user.toJson()),
    );
  }

  Future<void> clearCachedSession() async {
    final sharedPreferences = await SharedPreferences.getInstance();
    await sharedPreferences.remove(_cachedUserKey);
  }

  Future<bool> get hasPersistedSession async {
    final cachedUser = await getCachedUser();
    final cookies = getIt<ApiService>().cookies;
    final baseUrl = Uri.https(getIt<ApiService>().baseUrl);
    return cachedUser != null && cookies.getCookieHeader(baseUrl) != null;
  }

  Future<AuthBootstrapResult> bootstrapSession() async {
    final cachedUser = await getCachedUser();
    final hasPersistedSession = await this.hasPersistedSession;
    final isOnline = await _connectivityService.isOnline;

    if (!hasPersistedSession) {
      return AuthBootstrapResult(
        response: ApiResponse(success: false, message: 'No saved session'),
        usedCachedSession: false,
      );
    }

    if (!isOnline) {
      return AuthBootstrapResult(
        response: ApiResponse(
          success: cachedUser != null,
          data: cachedUser,
          message: cachedUser != null ? 'Offline session restored' : 'Offline and no cached user',
        ),
        usedCachedSession: cachedUser != null,
      );
    }

    final response = await getSession();
    if (response.success && response.data != null) {
      await cacheUser(response.data!);
      return AuthBootstrapResult(
        response: response,
        usedCachedSession: false,
      );
    }

    if (cachedUser != null) {
      return AuthBootstrapResult(
        response: ApiResponse(
          success: true,
          data: cachedUser,
          message: 'Using cached session while revalidation failed',
        ),
        usedCachedSession: true,
      );
    }

    return AuthBootstrapResult(
      response: response,
      usedCachedSession: false,
    );
  }

  Future<ApiResponse<User>> signup({
    required String name,
    required String email,
    required String password,
    String callbackURL = 'sad',
  }) async {
    final signupData = {
      'username': name,
      'name': name,
      'email': email,
      'password': password,
    };

    final response = await post(
      '/sign-up/email',
      body: signupData,
      parser: (value) => User.fromJson(value['user'] as Map<String, dynamic>),
    );

    if (response.success && response.data != null) {
      await cacheUser(response.data!);
    }

    return response;
  }

  Future<ApiResponse<User>> signin({
    required String username,
    required String password,
    String callbackURL = 'sad',
  }) async {
    if (!await _connectivityService.isOnline) {
      return ApiResponse(
        success: false,
        message: 'You need internet to sign in the first time.',
      );
    }

    final signinData = {
      'username': username,
      'password': password,
    };

    final response = await post(
      '/sign-in/username',
      body: signinData,
      parser: (value) => User.fromJson(value['user'] as Map<String, dynamic>),
    );

    if (response.success && response.data != null) {
      await cacheUser(response.data!);
    }

    return response;
  }

  Future<ApiResponse<dynamic>> signout() async {
    LoadingOverlay.show();

    if (!await _connectivityService.isOnline) {
      return ApiResponse(
        success: false,
        message: 'Connect to the internet before signing out.',
      );
    }

    return post('/sign-out');
  }
}
