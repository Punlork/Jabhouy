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
import 'package:jabhouy_net/jabhouy_net.dart';
import 'package:jabhouy_sync/jabhouy_sync.dart';
import 'package:jabhouy_ui/jabhouy_ui.dart';

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
    ..registerLazySingleton(() => ShopDao(getIt<AppDatabase>()))
    ..registerLazySingleton(() => ShopApi(getIt<ApiService>()))
    ..registerLazySingleton(() => CategoryDao(getIt<AppDatabase>()))
    ..registerLazySingleton(() => CategoryApi(getIt<ApiService>()))
    ..registerLazySingleton(() => CustomerDao(getIt<AppDatabase>()))
    ..registerLazySingleton(() => CustomerApi(getIt<ApiService>()))
    ..registerLazySingleton(() => LoanerDao(getIt<AppDatabase>()))
    ..registerLazySingleton(() => LoanerApi(getIt<ApiService>()))
    ..registerLazySingleton(() => IncomeDao(getIt<AppDatabase>()))
    ..registerLazySingleton(() => IncomeApi(getIt<ApiService>()))
    // One engine for the whole app: the outbox is one queue, and ordering
    // a shop item after its category only works if both drain together.
    ..registerLazySingleton(
      () => SyncEngine(
        database: getIt<AppDatabase>(),
        transport: AppSyncTransport([
          ShopSyncAdapter(getIt<ShopDao>(), getIt<ShopApi>()),
          CategorySyncAdapter(getIt<CategoryDao>(), getIt<CategoryApi>()),
          CustomerSyncAdapter(getIt<CustomerDao>(), getIt<CustomerApi>()),
          LoanerSyncAdapter(getIt<LoanerDao>(), getIt<LoanerApi>()),
          IncomeSyncAdapter(
            getIt<IncomeDao>(),
            getIt<FirebaseIncomeSyncService>().syncNotification,
            getIt<FirebaseIncomeSyncService>().canAcceptLocalCapture,
          ),
        ]),
      ),
    )
    ..registerLazySingleton<IncomeRepository>(
      () => DefaultIncomeRepository(
        getIt<IncomeDao>(),
        getIt<IncomeApi>(),
        getIt<SyncEngine>(),
      ),
    )
    ..registerLazySingleton(
      () => PullRemoteNotificationsUseCase(
        getIt<IncomeRepository>(),
        getIt<NotificationDiagnosticsService>(),
      ),
    )
    ..registerLazySingleton<ShopRepository>(
      () => DefaultShopRepository(
        getIt<ShopDao>(),
        getIt<ShopApi>(),
        getIt<SyncEngine>(),
        getIt<ConnectivityService>(),
      ),
    )
    ..registerLazySingleton<LoanerRepository>(
      () => DefaultLoanerRepository(
        getIt<LoanerDao>(),
        getIt<LoanerApi>(),
        getIt<SyncEngine>(),
        getIt<ConnectivityService>(),
      ),
    )
    ..registerLazySingleton(
      () => RefreshLoanersUseCase(
        getIt<LoanerRepository>(),
        getIt<CustomerRepository>(),
      ),
    )
    ..registerLazySingleton<CustomerRepository>(
      () => DefaultCustomerRepository(
        getIt<CustomerDao>(),
        getIt<CustomerApi>(),
        getIt<SyncEngine>(),
        getIt<ConnectivityService>(),
      ),
    )
    ..registerLazySingleton(
      () => IncomeService(
        getIt<IncomeRepository>(),
        getIt<PullRemoteNotificationsUseCase>(),
        getIt<NotificationTrackingBridge>(),
        getIt<FirebaseIncomeSyncService>(),
        getIt<NotificationDiagnosticsService>(),
      ),
    )
    ..registerLazySingleton<CategoryRepository>(
      () => DefaultCategoryRepository(
        getIt<CategoryDao>(),
        getIt<CategoryApi>(),
        getIt<SyncEngine>(),
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
    ..registerFactory(
      () => UploadBloc(UploadImageAdapter(getIt<UploadService>())),
    )
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
        getIt<ShopRepository>(),
        getIt<UploadBloc>(),
        getIt<ConnectivityService>(),
      ),
    )
    ..registerFactory(() => CategoryBloc(getIt<CategoryRepository>()))
    ..registerFactory(() => SigninBloc(getIt<AuthService>()))
    ..registerFactory(() => SignupBloc(getIt<AuthService>()))
    ..registerFactory(() => SignoutBloc(getIt<AuthService>()))
    ..registerFactory(
      () => LoanerBloc(
        getIt<LoanerRepository>(),
        getIt<RefreshLoanersUseCase>(),
        getIt<ConnectivityService>(),
      ),
    )
    ..registerFactory(
      () => CustomerBloc(
        getIt<CustomerRepository>(),
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
