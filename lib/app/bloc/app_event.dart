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
