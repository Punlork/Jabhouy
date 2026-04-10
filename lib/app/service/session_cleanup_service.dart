import 'package:my_app/app/service/api_service.dart';
import 'package:my_app/app/service/database/app_database.dart';
import 'package:my_app/auth/service/auth_service.dart';
import 'package:my_app/income/services/firebase_income_sync_service.dart';
import 'package:my_app/income/services/notification_diagnostics_service.dart';
import 'package:my_app/income/services/notification_tracking_bridge.dart';

class SessionCleanupService {
  SessionCleanupService({
    required ApiService apiService,
    required AuthService authService,
    required AppDatabase database,
    required FirebaseIncomeSyncService incomeSyncService,
    required NotificationTrackingBridge notificationTrackingBridge,
    required NotificationDiagnosticsService notificationDiagnosticsService,
  })  : _apiService = apiService,
        _authService = authService,
        _database = database,
        _incomeSyncService = incomeSyncService,
        _notificationTrackingBridge = notificationTrackingBridge,
        _notificationDiagnosticsService = notificationDiagnosticsService;

  final ApiService _apiService;
  final AuthService _authService;
  final AppDatabase _database;
  final FirebaseIncomeSyncService _incomeSyncService;
  final NotificationTrackingBridge _notificationTrackingBridge;
  final NotificationDiagnosticsService _notificationDiagnosticsService;

  Future<void> clearSignedInUserData() async {
    await _incomeSyncService.clearPersistedSessionState();
    await _notificationTrackingBridge.clearStoredTrackingState();
    await _notificationDiagnosticsService.clear();
    await _apiService.cookies.clearCookies();
    await _authService.clearCachedSession();
    await _database.clearUserData();
  }
}
