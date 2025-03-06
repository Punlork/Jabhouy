part of 'app_bloc.dart';

class AppState extends Equatable {
  const AppState({required this.locale, required this.isGridView});
  final Locale locale;
  final bool isGridView;

  @override
  List<Object?> get props => [locale, isGridView];
}
