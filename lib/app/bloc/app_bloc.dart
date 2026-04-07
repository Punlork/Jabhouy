import 'dart:async';
import 'dart:ui';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:my_app/income/income.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'app_event.dart';
part 'app_state.dart';

class AppBloc extends Bloc<AppEvent, AppState> {
  AppBloc(this._incomeSyncService)
      : super(
          const AppState(
            locale: Locale('en'),
            isGridView: true,
            isDarkMode: false,
            deviceRole: DeviceRole.sub,
          ),
        ) {
    on<InitializeApp>(_onInitializeApp);
    on<SwitchLanguage>(_onSwitchLanguage);
    on<SwitchViewMode>(_onSwitchViewMode);
    on<SwitchThemeMode>(_onSwitchThemeMode);
    on<RefreshDeviceRole>(_onRefreshDeviceRole);
    on<_DeviceRoleUpdated>(_onDeviceRoleUpdated);

    _deviceRoleSubscription = _incomeSyncService.deviceRoleStream.listen(
      (deviceRole) => add(_DeviceRoleUpdated(deviceRole: deviceRole)),
    );
    add(const InitializeApp());
  }

  final FirebaseIncomeSyncService _incomeSyncService;
  StreamSubscription<DeviceRole>? _deviceRoleSubscription;

  Future<void> _onInitializeApp(
    InitializeApp event,
    Emitter<AppState> emit,
  ) async {
    final sharedPref = await SharedPreferences.getInstance();
    final savedLocale = sharedPref.getString('locale') ?? 'km';
    final savedIsGridView = sharedPref.getBool('isGridView') ?? true;
    final savedIsDarkMode = sharedPref.getBool('isDarkMode') ?? false;
    final savedDeviceRole = await _incomeSyncService.getStoredDeviceRole();

    emit(
      AppState(
        locale: Locale(savedLocale),
        isGridView: savedIsGridView,
        isDarkMode: savedIsDarkMode,
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
    await sharedPref.setString('locale', newLocale.languageCode);
    emit(state.copyWith(locale: newLocale));
  }

  Future<void> _onSwitchViewMode(
    SwitchViewMode event,
    Emitter<AppState> emit,
  ) async {
    final sharedPref = await SharedPreferences.getInstance();
    await sharedPref.setBool('isGridView', event.isGridView);
    emit(state.copyWith(isGridView: event.isGridView));
  }

  Future<void> _onSwitchThemeMode(
    SwitchThemeMode event,
    Emitter<AppState> emit,
  ) async {
    final sharedPref = await SharedPreferences.getInstance();
    await sharedPref.setBool('isDarkMode', event.isDarkMode);
    emit(state.copyWith(isDarkMode: event.isDarkMode));
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
