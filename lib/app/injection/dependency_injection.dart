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
    ..registerSingleton<AppLogService>(AppLogService.instance)
    ..registerSingleton<NetworkInspectorService>(
      NetworkInspectorService.instance,
    )
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
      () => NotificationDiagnosticsService(
        getIt<NotificationTrackingBridge>(),
      ),
    )
    ..registerLazySingleton(
      () => FcmService(
        getIt<NotificationDiagnosticsService>(),
      ),
    )
    ..registerLazySingleton(
      () => FirebaseIncomeSyncService(
        getIt<ConnectivityService>(),
        getIt<AuthService>(),
        getIt<FcmService>(),
        getIt<ApiService>(),
        getIt<NotificationDiagnosticsService>(),
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
        getIt<NotificationDiagnosticsService>(),
      ),
    )
    ..registerLazySingleton(
      () => CategoryService(
        getIt<ApiService>(),
        getIt<AppDatabase>(),
        getIt<ConnectivityService>(),
      ),
    )
    ..registerLazySingleton(
      () => SessionCleanupService(
        apiService: getIt<ApiService>(),
        authService: getIt<AuthService>(),
        database: getIt<AppDatabase>(),
        incomeSyncService: getIt<FirebaseIncomeSyncService>(),
        notificationTrackingBridge: getIt<NotificationTrackingBridge>(),
        notificationDiagnosticsService: getIt<NotificationDiagnosticsService>(),
      ),
    )
    ..registerFactory(
      () => AppBloc(
        getIt<FirebaseIncomeSyncService>(),
        getIt<AppLogService>(),
        getIt<NetworkInspectorService>(),
      ),
    )
    ..registerFactory(() => UploadBloc(getIt<UploadService>()))
    ..registerFactory(
      () => AuthBloc(
        getIt<AuthService>(),
        getIt<ConnectivityService>(),
        getIt<SessionCleanupService>(),
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

  logger.i('Dependencies setup successfully');
}
