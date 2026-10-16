// ignore_for_file: avoid_dynamic_calls

import 'dart:convert';
import 'dart:math';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:jabhouy/app/app.dart';
import 'package:jabhouy_core/jabhouy_core.dart';
import 'package:jabhouy_net/jabhouy_net.dart';
import 'package:jabhouy_ui/jabhouy_ui.dart';
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
    ConnectivityService connectivityService, {
    GoogleSignIn? googleSignIn,
    FeatureFlags flags = const FixedFeatureFlags({}),
  }) =>
      AuthService._(
        apiService,
        connectivityService,
        googleSignIn ?? GoogleSignIn.instance,
        flags,
      );

  AuthService._(
    super.apiService,
    this._connectivityService,
    this._google,
    this._flags,
  );

  static const _cachedUserKey = 'cached_auth_user';
  static const _needsInternetToSignIn =
      'You need internet to sign in the first time.';

  final ConnectivityService _connectivityService;
  final GoogleSignIn _google;
  final FeatureFlags _flags;

  /// `GoogleSignIn.initialize` must run exactly once.
  Future<void>? _googleInitialized;

  @override
  String get basePath => '/auth';

  Future<ApiResponse<User?>> getSession() async {
    final res = await get(
      '/get-session',
      showSnackBar: false,
      parser: (value) => value != null
          ? User.fromJson(
              value['user'] as Map<String, dynamic>,
            )
          : null,
    );
    if (res.success && res.data == null) {
      return ApiResponse(
        success: false,
        message: 'Session is missing or expired.',
      );
    }
    return res;
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

    // A saved session opens the app at once, online or not; the bloc then
    // checks it with the server in the background (revalidateSession).
    // Waiting for that call held the splash for a second or more.
    if (cachedUser != null &&
        (hasPersistedSession || !await _connectivityService.isOnline)) {
      return AuthBootstrapResult(
        response: ApiResponse(
          success: true,
          data: cachedUser,
          message: 'Cached session restored',
        ),
        usedCachedSession: true,
      );
    }

    // hasPersistedSession needs a cached user, so none was saved.
    return AuthBootstrapResult(
      response: ApiResponse(success: false, message: 'No saved session'),
      usedCachedSession: false,
    );
  }

  bool _isRecoverableSessionFailure(String? message) {
    if (message == null) return false;
    final normalized = message.toLowerCase();
    return normalized.contains('network error') ||
        normalized.contains('socket') ||
        normalized.contains('timeout') ||
        normalized.contains('failed host lookup');
  }

  /// Checks with the server a session the app opened on from cache.
  ///
  /// Null when the server could not be reached: the cached session stays,
  /// as it would have at launch. Otherwise the server's answer; a failed
  /// one has already cleared the cached session.
  Future<ApiResponse<User?>?> revalidateSession() async {
    final response = await getSession();
    if (response.success && response.data != null) {
      await cacheUser(response.data!);
      return response;
    }
    if (_isRecoverableSessionFailure(response.message)) return null;
    await clearCachedSession();
    return response;
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
      return ApiResponse(success: false, message: _needsInternetToSignIn);
    }

    final signinData = {
      'username': username,
      'password': password,
    };

    // The sign-in page shows the failure, so no snackbar here as well.
    final response = await post(
      '/sign-in/username',
      body: signinData,
      showSnackBar: false,
      parser: (value) => User.fromJson(value['user'] as Map<String, dynamic>),
    );

    if (response.success && response.data != null) {
      await cacheUser(response.data!);
    }

    return response;
  }

  /// Null when the user closes the Google dialog.
  ///
  /// Other Google failures throw [GoogleSignInException].
  Future<ApiResponse<User>?> signInWithGoogle() async {
    if (!await _connectivityService.isOnline) {
      return ApiResponse(success: false, message: _needsInternetToSignIn);
    }

    final GoogleSignInAccount account;
    try {
      await _initializeGoogle();
      account = await _google.authenticate();
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return null;
      rethrow;
    }

    final response = await post(
      '/sign-in/social',
      body: {
        'provider': 'google',
        'idToken': {'token': account.authentication.idToken},
      },
      showSnackBar: false,
      parser: (value) => User.fromJson(value['user'] as Map<String, dynamic>),
    );

    if (response.success && response.data != null) {
      await cacheUser(response.data!);
    }

    return response;
  }

  Future<void> _initializeGoogle() => _googleInitialized ??= _google.initialize(
        serverClientId: dotenv.get('GOOGLE_SERVER_CLIENT_ID'),
      );

  /// Up to [count] free Usernames built from [user]'s name and email.
  ///
  /// Empty when none can be built or checked; the picker still takes a
  /// typed one.
  Future<List<String>> usernameSuggestions(User user, {int count = 3}) async {
    final name = _usernameBase(user.name ?? '', '_');
    final email = _usernameBase((user.email ?? '').split('@').first, '_');
    final suffix = 100 + Random().nextInt(900);
    final candidates = {
      name,
      email,
      _usernameBase(user.name ?? '', '.'),
      '$name$suffix',
      '$email$suffix',
    }.where(isValidUsername).toList();

    final available = await Future.wait(candidates.map(_isUsernameAvailable));
    return [
      for (var i = 0; i < candidates.length; i++)
        if (available[i]) candidates[i],
    ].take(count).toList();
  }

  /// The username plugin's default rules.
  static bool isValidUsername(String value) =>
      value.length >= 3 && value.length <= 30 && RegExp(r'^[a-zA-Z0-9_.]+$').hasMatch(value);

  /// Lowercase, words joined by [separator], other characters dropped.
  String _usernameBase(String text, String separator) {
    final base = text
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'\s+'), separator)
        .replaceAll(RegExp('[^a-z0-9_.]'), '');
    return base.length > 26 ? base.substring(0, 26) : base;
  }

  Future<bool> _isUsernameAvailable(String username) async {
    final response = await post(
      '/is-username-available',
      body: {'username': username},
      showSnackBar: false,
      parser: (value) => value is Map && value['available'] == true,
    );
    return response.success && (response.data ?? false);
  }

  Future<ApiResponse<dynamic>> signout() async {
    LoadingOverlay.show();

    if (!await _connectivityService.isOnline) {
      return ApiResponse(
        success: false,
        message: 'Connect to the internet before signing out.',
      );
    }

    final response = await post<dynamic>('/sign-out');
    // Forget the Google account too, so on a shared phone the next person
    // gets the account chooser. Too late to fail the sign-out over it.
    if (response.success && _flags.isEnabled(Feature.googleSignIn)) {
      try {
        await _initializeGoogle();
        await _google.signOut();
      } catch (_) {}
    }
    return response;
  }
}
