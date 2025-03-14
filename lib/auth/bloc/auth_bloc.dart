import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:my_app/app/app.dart';
import 'package:my_app/auth/service/auth_service.dart';

part 'auth_event.dart';
part 'auth_state.dart';

extension ShopStateExtension on AuthState {
  Authenticated? get asAuthenticated => this is Authenticated ? this as Authenticated : null;
}

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(this.authService) : super(AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthSignedIn>(_onAuthSignedIn);
    on<AuthSignedOut>(_onAuthSignedOut);
  }

  final AuthService authService;

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      final response = await authService.getSession();

      if (response.success && response.data != null) {
        emit(Authenticated(response.data!));
      } else {
        emit(Unauthenticated());
      }
    } catch (e) {
      emit(Unauthenticated());
    }
  }

  void _onAuthSignedIn(
    AuthSignedIn event,
    Emitter<AuthState> emit,
  ) =>
      add(AuthCheckRequested());

  Future<void> _onAuthSignedOut(
    AuthSignedOut event,
    Emitter<AuthState> emit,
  ) async {
    final apiService = getIt<ApiService>();
    await apiService.cookies.clearCookies();
    emit(Unauthenticated());
  }
}
