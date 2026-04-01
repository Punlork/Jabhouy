import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:meta/meta.dart';
import 'package:my_app/app/app.dart';
import 'package:my_app/auth/service/auth_service.dart';

part 'auth_event.dart';
part 'auth_state.dart';

extension AuthStateExtension on AuthState {
  Authenticated? get asAuthenticated => this is Authenticated ? this as Authenticated : null;
}

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(this.authService, this._connectivityService) : super(AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthSignedIn>(_onAuthSignedIn);
    on<AuthSignedOut>(_onAuthSignedOut);
    on<_AuthConnectivityChanged>(_onConnectivityChanged);

    _connectivitySubscription = _connectivityService.connectivityStream.listen(
      (isOnline) => add(_AuthConnectivityChanged(isOnline: isOnline)),
    );
  }

  final AuthService authService;
  final ConnectivityService _connectivityService;
  late final StreamSubscription<bool> _connectivitySubscription;

  @override
  Future<void> close() {
    _connectivitySubscription.cancel();
    return super.close();
  }

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    final bootstrap = await authService.bootstrapSession();
    final response = bootstrap.response;
    final isOnline = await _connectivityService.isOnline;

    if (response.success && response.data != null) {
      emit(
        Authenticated(
          response.data!,
          isOffline: !isOnline,
          isSessionTrusted: isOnline && !bootstrap.usedCachedSession,
        ),
      );
    } else {
      await authService.clearCachedSession();
      emit(Unauthenticated());
    }

    Future.delayed(
      const Duration(milliseconds: 500),
      FlutterNativeSplash.remove,
    );
  }

  Future<void> _onAuthSignedIn(
    AuthSignedIn event,
    Emitter<AuthState> emit,
  ) async {
    await authService.cacheUser(event.user);
    emit(AuthLoading());
    add(AuthCheckRequested());
  }

  Future<void> _onAuthSignedOut(
    AuthSignedOut event,
    Emitter<AuthState> emit,
  ) async {
    final apiService = getIt<ApiService>();
    await apiService.cookies.clearCookies();
    await authService.clearCachedSession();
    emit(Unauthenticated());
  }

  Future<void> _onConnectivityChanged(
    _AuthConnectivityChanged event,
    Emitter<AuthState> emit,
  ) async {
    final currentState = state.asAuthenticated;
    if (currentState == null) {
      return;
    }

    if (!event.isOnline) {
      emit(
        Authenticated(
          currentState.user,
          isOffline: true,
          isSessionTrusted: currentState.isSessionTrusted,
        ),
      );
      return;
    }

    final response = await authService.getSession();
    if (response.success && response.data != null) {
      await authService.cacheUser(response.data!);
      emit(
        Authenticated(
          response.data!,
        ),
      );
      return;
    }

    emit(
      Authenticated(
        currentState.user,
        isSessionTrusted: false,
      ),
    );
  }
}
