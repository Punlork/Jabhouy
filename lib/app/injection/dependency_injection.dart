import 'package:get_it/get_it.dart';
import 'package:jabhouy/app/app.dart';
import 'package:jabhouy/app/service/database/database_connection.dart';
import 'package:jabhouy/auth/auth.dart';
import 'package:jabhouy/customer/customer.dart';
import 'package:jabhouy/income/income.dart';
import 'package:jabhouy/loaner/loaner.dart';
import 'package:jabhouy/profile/profile.dart';
import 'package:jabhouy/shop/shop.dart';
import 'package:jabhouy_core/jabhouy_core.dart';

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
    ..registerSingleton<AppDatabase>(AppDatabase(openAppDatabaseConnection()))
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
        getIt<ApiService>(),
        getIt<NotificationDiagnosticsService>(),
      ),
    )
    ..registerLazySingleton(
      () => FirebaseIncomeSyncService(
        getIt<ConnectivityService>(),
        getIt<AuthService>(),
        getIt<FcmService>(),
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
        getIt<ApiService>(),
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
    ..registerFactory(
      () => IncomeBloc(
        getIt<IncomeService>(),
        getIt<FcmService>(),
      ),
    );

  logger.i('Dependencies setup successfully');
}
