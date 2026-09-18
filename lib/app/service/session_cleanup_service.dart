import 'package:jabhouy/app/service/api_service.dart';
import 'package:jabhouy/app/service/database/app_database.dart';
import 'package:jabhouy/auth/service/auth_service.dart';
import 'package:jabhouy/income/services/firebase_income_sync_service.dart';
import 'package:jabhouy/income/services/notification_diagnostics_service.dart';
import 'package:jabhouy/income/services/notification_tracking_bridge.dart';

class SessionCleanupService {
  SessionCleanupService({
    required this._apiService,
    required this._authService,
    required this._database,
    required this._incomeSyncService,
    required this._notificationTrackingBridge,
    required this._notificationDiagnosticsService,
  });

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
