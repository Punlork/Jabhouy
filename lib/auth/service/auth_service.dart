// ignore_for_file: avoid_dynamic_calls

import 'package:my_app/app/app.dart';
import 'package:my_app/auth/auth.dart';

class AuthService {
  AuthService(this._apiService);

  final ApiService _apiService;

  String get _auth => '/auth';

  Future<ApiResponse<User?>> getSession() async {
    final response = await _apiService.get(
      '$_auth/get-session',
      parser: (value) => value != null
          ? User.fromJson(
              value['user'] as Map<String, dynamic>,
            )
          : null,
    );

    return ApiResponse(
      success: response.success,
      data: response.data,
      message: response.message,
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

    final response = await _apiService.post(
      '$_auth/sign-up/email',
      body: signupData,
      parser: (value) => User.fromJson(
        value['user'] as Map<String, dynamic>,
      ),
    );

    return ApiResponse(
      success: response.success,
      data: response.data,
      message: response.message,
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

    final response = await _apiService.post(
      '$_auth/sign-in/email',
      body: signinData,
      parser: (value) => User.fromJson(
        value['user'] as Map<String, dynamic>,
      ),
    );

    return ApiResponse(
      success: response.success,
      data: response.data,
      message: response.message,
    );
  }

  Future<ApiResponse<dynamic>> signout() async {
    LoadingOverlay.show();

    final response = await _apiService.post<dynamic>(
      '$_auth/sign-out',
    );

    return ApiResponse(
      success: response.success,
      data: response.data,
      message: response.message,
    );
  }
}
