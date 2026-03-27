part of 'app_bloc.dart';

class AppState extends Equatable {
  const AppState({
    required this.locale,
    required this.isGridView,
    required this.isDarkMode,
  });
  final Locale locale;
  final bool isGridView;
  final bool isDarkMode;

  AppState copyWith({
    Locale? locale,
    bool? isGridView,
    bool? isDarkMode,
  }) {
    return AppState(
      locale: locale ?? this.locale,
      isGridView: isGridView ?? this.isGridView,
      isDarkMode: isDarkMode ?? this.isDarkMode,
    );
  }

  @override
  List<Object?> get props => [locale, isGridView, isDarkMode];
}
