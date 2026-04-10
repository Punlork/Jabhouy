part of 'app_bloc.dart';

abstract class AppEvent extends Equatable {
  const AppEvent();

  @override
  List<Object?> get props => [];
}

class InitializeApp extends AppEvent {
  const InitializeApp();
}

class SwitchLanguage extends AppEvent {
  const SwitchLanguage(this.locale);
  final String locale;

  @override
  List<Object?> get props => [locale];
}

class SwitchViewMode extends AppEvent {
  const SwitchViewMode({required this.isGridView});
  final bool isGridView;

  @override
  List<Object?> get props => [isGridView];
}

class SwitchThemeMode extends AppEvent {
  const SwitchThemeMode({required this.isDarkMode});
  final bool isDarkMode;

  @override
  List<Object?> get props => [isDarkMode];
}

class SwitchAppLogCapture extends AppEvent {
  const SwitchAppLogCapture({required this.isEnabled});
  final bool isEnabled;

  @override
  List<Object?> get props => [isEnabled];
}

class SwitchNetworkLogCapture extends AppEvent {
  const SwitchNetworkLogCapture({required this.isEnabled});
  final bool isEnabled;

  @override
  List<Object?> get props => [isEnabled];
}

class RefreshDeviceRole extends AppEvent {
  const RefreshDeviceRole();
}

class _DeviceRoleUpdated extends AppEvent {
  const _DeviceRoleUpdated({required this.deviceRole});
  final DeviceRole deviceRole;

  @override
  List<Object?> get props => [deviceRole];
}
