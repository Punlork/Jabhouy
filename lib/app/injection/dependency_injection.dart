import 'dart:developer';

import 'package:get_it/get_it.dart';
import 'package:my_app/app/app.dart';
import 'package:my_app/auth/auth.dart';
import 'package:my_app/auth/bloc/signout/signout_bloc.dart';
import 'package:my_app/shop/shop.dart';

final getIt = GetIt.instance;

Future<void> setupDependencies() async {
  // Register ApiService as a singleton and initialize cookies
  final apiService = ApiService();
  await apiService.cookies.initCookies();
  getIt
    ..registerSingleton<ApiService>(apiService)
    ..registerLazySingleton(() => UploadService(getIt<ApiService>()))
    ..registerLazySingleton(() => ShopService(getIt<ApiService>()))
    ..registerLazySingleton(() => AuthService(getIt<ApiService>()))
    ..registerLazySingleton(() => CategoryService(getIt<ApiService>()))
    ..registerFactory(AppBloc.new)
    ..registerFactory(() => UploadBloc(getIt<UploadService>()))
    ..registerFactory(() => AuthBloc(getIt<AuthService>())..add(AuthCheckRequested()))
    ..registerFactory(() => ShopBloc(getIt<ShopService>(), getIt<UploadBloc>()))
    ..registerFactory(() => CategoryBloc(getIt<CategoryService>()))
    ..registerFactory(() => SigninBloc(getIt<AuthService>()))
    ..registerFactory(() => SignupBloc(getIt<AuthService>()))
    ..registerFactory(() => SignoutBloc(getIt<AuthService>()));

  log('Dependencies setup successfully');
}
