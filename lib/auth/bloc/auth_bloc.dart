import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:jabhouy/app/app.dart';
import 'package:jabhouy/auth/service/auth_service.dart';
import 'package:jabhouy_net/jabhouy_net.dart';

part 'auth_event.dart';
part 'auth_state.dart';

extension AuthStateExtension on AuthState {
  Authenticated? get asAuthenticated => this is Authenticated ? this as Authenticated : null;
}

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(
    this.authService,
    this._connectivityService,
    this._sessionCleanupService,
  ) : super(AuthInitial()) {
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
  final SessionCleanupService _sessionCleanupService;
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
    var revalidate = false;
    try {
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
        revalidate = isOnline && bootstrap.usedCachedSession;
      } else {
        await authService.clearCachedSession();
        emit(const Unauthenticated());
      }
    } catch (_) {
      await authService.clearCachedSession();
      emit(const Unauthenticated());
    } finally {
      // Once the screen for this state has drawn, instead of a fixed
      // 500 ms on top of the auth check.
      WidgetsBinding.instance
        ..addPostFrameCallback((_) => FlutterNativeSplash.remove())
        ..scheduleFrame();
    }

    if (revalidate) await _revalidateCachedSession(emit);
  }

  /// The app opened on the cached session; now ask the server. A rejected
  /// session signs out; an unreachable server leaves it as it is.
  Future<void> _revalidateCachedSession(Emitter<AuthState> emit) async {
    final response = await authService.revalidateSession();
    if (response == null || state is! Authenticated) return;
    if (response.success && response.data != null) {
      emit(Authenticated(response.data!));
    } else {
      emit(const Unauthenticated(sessionExpired: true));
    }
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
    await _sessionCleanupService.clearSignedInUserData();
    emit(const Unauthenticated());
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
