import 'dart:developer';

import 'package:get_it/get_it.dart';
import 'package:my_app/app/app.dart';
import 'package:my_app/auth/auth.dart';
import 'package:my_app/loaner/loaner.dart';
import 'package:my_app/profile/profile.dart';
import 'package:my_app/shop/shop.dart';

final getIt = GetIt.instance;

Future<void> setupDependencies() async {
  final apiService = ApiService();
  await apiService.cookies.initCookies();
  getIt
    ..registerSingleton<ApiService>(apiService)
    ..registerLazySingleton(() => UploadService(getIt<ApiService>()))
    ..registerLazySingleton(() => ProfileService(getIt<ApiService>()))
    ..registerLazySingleton(() => ShopService(getIt<ApiService>()))
    ..registerLazySingleton(() => AuthService(getIt<ApiService>()))
    ..registerLazySingleton(() => CategoryService(getIt<ApiService>()))
    ..registerFactory(AppBloc.new)
    ..registerFactory(() => UploadBloc(getIt<UploadService>()))
    ..registerFactory(() => AuthBloc(getIt<AuthService>())..add(AuthCheckRequested()))
    ..registerFactory(() => ProfileBloc(getIt<UploadBloc>(), getIt<ProfileService>()))
    ..registerFactory(() => ShopBloc(getIt<ShopService>(), getIt<UploadBloc>()))
    ..registerFactory(() => CategoryBloc(getIt<CategoryService>()))
    ..registerFactory(() => SigninBloc(getIt<AuthService>()))
    ..registerFactory(() => SignupBloc(getIt<AuthService>()))
    ..registerFactory(() => SignoutBloc(getIt<AuthService>()))
    ..registerFactory(LoanerBloc.new);

  log('Dependencies setup successfully');
}
