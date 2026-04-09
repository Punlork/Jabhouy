import 'dart:async';
import 'dart:ui';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:my_app/app/app.dart';
import 'package:my_app/income/income.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'app_event.dart';
part 'app_state.dart';

class AppBloc extends Bloc<AppEvent, AppState> {
  AppBloc(
    this._incomeSyncService,
    this._appLogService,
    this._networkInspectorService,
  ) : super(
          const AppState(
            locale: Locale('en'),
            isGridView: true,
            isDarkMode: false,
            isAppLogCaptureEnabled: !kReleaseMode,
            isNetworkLogCaptureEnabled: !kReleaseMode,
            deviceRole: DeviceRole.sub,
          ),
        ) {
    on<InitializeApp>(_onInitializeApp);
    on<SwitchLanguage>(_onSwitchLanguage);
    on<SwitchViewMode>(_onSwitchViewMode);
    on<SwitchThemeMode>(_onSwitchThemeMode);
    on<SwitchAppLogCapture>(_onSwitchAppLogCapture);
    on<SwitchNetworkLogCapture>(_onSwitchNetworkLogCapture);
    on<RefreshDeviceRole>(_onRefreshDeviceRole);
    on<_DeviceRoleUpdated>(_onDeviceRoleUpdated);

    _deviceRoleSubscription = _incomeSyncService.deviceRoleStream.listen(
      (deviceRole) => add(_DeviceRoleUpdated(deviceRole: deviceRole)),
    );
    add(const InitializeApp());
  }

  final FirebaseIncomeSyncService _incomeSyncService;
  final AppLogService _appLogService;
  final NetworkInspectorService _networkInspectorService;
  StreamSubscription<DeviceRole>? _deviceRoleSubscription;
  static const _localeKey = 'locale';
  static const _gridViewKey = 'isGridView';
  static const _darkModeKey = 'isDarkMode';
  static const _appLogCaptureKey = 'isAppLogCaptureEnabled';
  static const _networkLogCaptureKey = 'isNetworkLogCaptureEnabled';

  Future<void> _onInitializeApp(
    InitializeApp event,
    Emitter<AppState> emit,
  ) async {
    final sharedPref = await SharedPreferences.getInstance();
    final savedLocale = sharedPref.getString(_localeKey) ?? 'km';
    final savedIsGridView = sharedPref.getBool(_gridViewKey) ?? true;
    final savedIsDarkMode = sharedPref.getBool(_darkModeKey) ?? false;
    final savedIsAppLogCapture =
        sharedPref.getBool(_appLogCaptureKey) ?? !kReleaseMode;
    final savedIsNetworkLogCapture =
        sharedPref.getBool(_networkLogCaptureKey) ?? !kReleaseMode;
    final savedDeviceRole = await _incomeSyncService.getStoredDeviceRole();

    _appLogService.captureEnabled = savedIsAppLogCapture;
    _networkInspectorService.captureEnabled = savedIsNetworkLogCapture;

    emit(
      AppState(
        locale: Locale(savedLocale),
        isGridView: savedIsGridView,
        isDarkMode: savedIsDarkMode,
        isAppLogCaptureEnabled: savedIsAppLogCapture,
        isNetworkLogCaptureEnabled: savedIsNetworkLogCapture,
        deviceRole: savedDeviceRole,
      ),
    );

    add(const RefreshDeviceRole());
  }

  Future<void> _onSwitchLanguage(
    SwitchLanguage event,
    Emitter<AppState> emit,
  ) async {
    final newLocale =
        event.locale == 'en' ? const Locale('km') : const Locale('en');
    final sharedPref = await SharedPreferences.getInstance();
    await sharedPref.setString(_localeKey, newLocale.languageCode);
    emit(state.copyWith(locale: newLocale));
  }

  Future<void> _onSwitchViewMode(
    SwitchViewMode event,
    Emitter<AppState> emit,
  ) async {
    final sharedPref = await SharedPreferences.getInstance();
    await sharedPref.setBool(_gridViewKey, event.isGridView);
    emit(state.copyWith(isGridView: event.isGridView));
  }

  Future<void> _onSwitchThemeMode(
    SwitchThemeMode event,
    Emitter<AppState> emit,
  ) async {
    final sharedPref = await SharedPreferences.getInstance();
    await sharedPref.setBool(_darkModeKey, event.isDarkMode);
    emit(state.copyWith(isDarkMode: event.isDarkMode));
  }

  Future<void> _onSwitchAppLogCapture(
    SwitchAppLogCapture event,
    Emitter<AppState> emit,
  ) async {
    final sharedPref = await SharedPreferences.getInstance();
    await sharedPref.setBool(_appLogCaptureKey, event.isEnabled);
    _appLogService.captureEnabled = event.isEnabled;
    emit(state.copyWith(isAppLogCaptureEnabled: event.isEnabled));
  }

  Future<void> _onSwitchNetworkLogCapture(
    SwitchNetworkLogCapture event,
    Emitter<AppState> emit,
  ) async {
    final sharedPref = await SharedPreferences.getInstance();
    await sharedPref.setBool(_networkLogCaptureKey, event.isEnabled);
    _networkInspectorService.captureEnabled = event.isEnabled;
    emit(state.copyWith(isNetworkLogCaptureEnabled: event.isEnabled));
  }

  Future<void> _onRefreshDeviceRole(
    RefreshDeviceRole event,
    Emitter<AppState> emit,
  ) async {
    final deviceRole = await _incomeSyncService.refreshDeviceRole();
    if (deviceRole != state.deviceRole) {
      emit(state.copyWith(deviceRole: deviceRole));
    }
  }

  void _onDeviceRoleUpdated(
    _DeviceRoleUpdated event,
    Emitter<AppState> emit,
  ) {
    emit(state.copyWith(deviceRole: event.deviceRole));
  }

  @override
  Future<void> close() async {
    await _deviceRoleSubscription?.cancel();
    return super.close();
  }
}
