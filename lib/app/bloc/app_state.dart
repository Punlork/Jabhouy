part of 'app_bloc.dart';

enum DeviceRole {
  main('main'),
  sub('sub');

  const DeviceRole(this.storageValue);

  final String storageValue;

  bool get isMain => this == DeviceRole.main;
  bool get isSub => this == DeviceRole.sub;

  static DeviceRole fromStorage(String? value) {
    switch (value) {
      case 'sub':
        return DeviceRole.sub;
      case 'main':
        return DeviceRole.main;
      default:
        return DeviceRole.sub;
    }
  }
}

class AppState extends Equatable {
  const AppState({
    required this.locale,
    required this.isGridView,
    required this.isDarkMode,
    required this.deviceRole,
  });
  final Locale locale;
  final bool isGridView;
  final bool isDarkMode;
  final DeviceRole deviceRole;

  AppState copyWith({
    Locale? locale,
    bool? isGridView,
    bool? isDarkMode,
    DeviceRole? deviceRole,
  }) {
    return AppState(
      locale: locale ?? this.locale,
      isGridView: isGridView ?? this.isGridView,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      deviceRole: deviceRole ?? this.deviceRole,
    );
  }

  @override
  List<Object?> get props => [locale, isGridView, isDarkMode, deviceRole];
}
