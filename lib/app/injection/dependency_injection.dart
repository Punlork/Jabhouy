import 'dart:developer';

import 'package:get_it/get_it.dart';
import 'package:my_app/app/app.dart';
import 'package:my_app/app/service/database/app_database.dart';
import 'package:my_app/auth/auth.dart';
import 'package:my_app/customer/customer.dart';
import 'package:my_app/income/income.dart';
import 'package:my_app/loaner/loaner.dart';
import 'package:my_app/profile/profile.dart';
import 'package:my_app/shop/shop.dart';

final getIt = GetIt.instance;

Future<void> setupDependencies() async {
  final apiService = ApiService();
  await apiService.cookies.initCookies();
  getIt
    ..registerSingleton<ApiService>(apiService)
    ..registerSingleton<AppDatabase>(AppDatabase())
    ..registerSingleton(ConnectivityService())
    ..registerLazySingleton(() => UploadService(getIt<ApiService>()))
    ..registerLazySingleton(() => ProfileService(getIt<ApiService>()))
    ..registerLazySingleton(
      () => AuthService(
        getIt<ApiService>(),
        getIt<ConnectivityService>(),
      ),
    )
    ..registerLazySingleton(NotificationTrackingBridge.new)
    ..registerLazySingleton(
      () => FirebaseIncomeSyncService(
        getIt<ConnectivityService>(),
        getIt<AuthService>(),
      ),
    )
    ..registerLazySingleton(
      () => ShopService(
        getIt<ApiService>(),
        getIt<AppDatabase>(),
        getIt<ConnectivityService>(),
      ),
    )
    ..registerLazySingleton(
      () => LoanerService(
        getIt<ApiService>(),
        getIt<AppDatabase>(),
        getIt<ConnectivityService>(),
      ),
    )
    ..registerLazySingleton(
      () => CustomerService(
        getIt<ApiService>(),
        getIt<AppDatabase>(),
        getIt<ConnectivityService>(),
      ),
    )
    ..registerLazySingleton(
      () => IncomeService(
        getIt<AppDatabase>(),
        getIt<NotificationTrackingBridge>(),
        getIt<FirebaseIncomeSyncService>(),
      ),
    )
    ..registerLazySingleton(
      () => CategoryService(
        getIt<ApiService>(),
        getIt<AppDatabase>(),
        getIt<ConnectivityService>(),
      ),
    )
    ..registerFactory(AppBloc.new)
    ..registerFactory(() => UploadBloc(getIt<UploadService>()))
    ..registerFactory(
      () => AuthBloc(
        getIt<AuthService>(),
        getIt<ConnectivityService>(),
      )..add(AuthCheckRequested()),
    )
    ..registerFactory(
      () => ProfileBloc(
        getIt<UploadBloc>(),
        getIt<ProfileService>(),
      ),
    )
    ..registerFactory(
      () => ShopBloc(
        getIt<ShopService>(),
        getIt<UploadBloc>(),
        getIt<ConnectivityService>(),
      ),
    )
    ..registerFactory(() => CategoryBloc(getIt<CategoryService>()))
    ..registerFactory(() => SigninBloc(getIt<AuthService>()))
    ..registerFactory(() => SignupBloc(getIt<AuthService>()))
    ..registerFactory(() => SignoutBloc(getIt<AuthService>()))
    ..registerFactory(
      () => LoanerBloc(
        getIt<LoanerService>(),
        getIt<ConnectivityService>(),
      ),
    )
    ..registerFactory(
      () => CustomerBloc(
        getIt<CustomerService>(),
        getIt<ConnectivityService>(),
      ),
    )
    ..registerFactory(() => IncomeBloc(getIt<IncomeService>()));

  log('Dependencies setup successfully');
}
