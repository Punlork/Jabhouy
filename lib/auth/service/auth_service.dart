// ignore_for_file: avoid_dynamic_calls

import 'package:my_app/app/app.dart';

class AuthService extends BaseService {
  factory AuthService(ApiService apiService) => AuthService._(apiService);
  AuthService._(super.apiService);

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

  Future<ApiResponse<User>> signup({
    required String name,
    required String email,
    required String password,
    String callbackURL = 'sad',
  }) async {
    final signupData = {
      'name': name,
      'email': email,
      'password': password,
    };

    return post(
      '/sign-up/email',
      body: signupData,
      parser: (value) => User.fromJson(value['user'] as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<User>> signin({
    required String email,
    required String password,
    String callbackURL = 'sad',
  }) async {
    final signinData = {
      'email': email,
      'password': password,
    };

    return post(
      '/sign-in/email',
      body: signinData,
      parser: (value) => User.fromJson(value['user'] as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<dynamic>> signout() async {
    LoadingOverlay.show();
    return post('/sign-out');
  }
}
