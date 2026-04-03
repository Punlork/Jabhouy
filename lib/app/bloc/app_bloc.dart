import 'dart:ui';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'app_event.dart';
part 'app_state.dart';

class AppBloc extends Bloc<AppEvent, AppState> {
  AppBloc()
      : super(
          const AppState(
            locale: Locale('en'),
            isGridView: true,
            isDarkMode: false,
            deviceRole: DeviceRole.main,
          ),
        ) {
    on<InitializeApp>(_onInitializeApp);
    on<SwitchLanguage>(_onSwitchLanguage);
    on<SwitchViewMode>(_onSwitchViewMode);
    on<SwitchThemeMode>(_onSwitchThemeMode);
    on<SwitchDeviceRole>(_onSwitchDeviceRole);
    add(const InitializeApp());
  }

  Future<void> _onInitializeApp(
    InitializeApp event,
    Emitter<AppState> emit,
  ) async {
    final sharedPref = await SharedPreferences.getInstance();
    final savedLocale = sharedPref.getString('locale') ?? 'km';
    final savedIsGridView = sharedPref.getBool('isGridView') ?? true;
    final savedIsDarkMode = sharedPref.getBool('isDarkMode') ?? false;
    final savedDeviceRole = DeviceRole.fromStorage(
      sharedPref.getString('deviceRole'),
    );

    emit(
      AppState(
        locale: Locale(savedLocale),
        isGridView: savedIsGridView,
        isDarkMode: savedIsDarkMode,
        deviceRole: savedDeviceRole,
      ),
    );
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

  Future<void> _onSwitchDeviceRole(
    SwitchDeviceRole event,
    Emitter<AppState> emit,
  ) async {
    final sharedPref = await SharedPreferences.getInstance();
    await sharedPref.setString('deviceRole', event.deviceRole.storageValue);
    emit(state.copyWith(deviceRole: event.deviceRole));
  }
}
