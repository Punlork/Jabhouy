import 'dart:ui';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'app_event.dart';
part 'app_state.dart';

class AppBloc extends Bloc<AppEvent, AppState> {
  AppBloc() : super(const AppState(locale: Locale('en'), isGridView: true)) {
    on<InitializeApp>(_onInitializeApp);
    on<SwitchLanguage>(_onSwitchLanguage);
    on<SwitchViewMode>(_onSwitchViewMode);
    add(const InitializeApp());
  }

  Future<void> _onInitializeApp(InitializeApp event, Emitter<AppState> emit) async {
    final sharedPref = await SharedPreferences.getInstance();
    final savedLocale = sharedPref.getString('locale') ?? 'km';
    final savedIsGridView = sharedPref.getBool('isGridView') ?? true;

    emit(AppState(locale: Locale(savedLocale), isGridView: savedIsGridView));
  }

  Future<void> _onSwitchLanguage(SwitchLanguage event, Emitter<AppState> emit) async {
    final newLocale = event.locale == 'en' ? const Locale('km') : const Locale('en');
    final sharedPref = await SharedPreferences.getInstance();
    await sharedPref.setString('locale', newLocale.languageCode);
    emit(AppState(locale: newLocale, isGridView: state.isGridView));
  }

  Future<void> _onSwitchViewMode(SwitchViewMode event, Emitter<AppState> emit) async {
    final sharedPref = await SharedPreferences.getInstance();
    await sharedPref.setBool('isGridView', event.isGridView);
    emit(AppState(locale: state.locale, isGridView: event.isGridView));
  }
}
