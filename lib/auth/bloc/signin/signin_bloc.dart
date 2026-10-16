import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:jabhouy/app/app.dart';
import 'package:jabhouy/auth/auth.dart';

part 'signin_event.dart';
part 'signin_state.dart';

class SigninBloc extends Bloc<SigninEvent, SigninState> {
  SigninBloc(this.apiService) : super(SigninInitial()) {
    on<SigninSubmitted>(_onSigninSubmitted);
    on<SigninWithGoogleRequested>(_onSigninWithGoogleRequested);
  }

  final AuthService apiService;

  Future<void> _onSigninSubmitted(
    SigninSubmitted event,
    Emitter<SigninState> emit,
  ) async {
    emit(SigninLoading());

    try {
      final response = await apiService.signin(
        username: event.username,
        password: event.password,
      );

      if (response.success) {
        emit(SigninSuccess(response.data!));
      } else {
        emit(SigninFailure(response.message ?? 'Unknown error'));
      }
    } catch (e) {
      emit(SigninFailure(e.toString()));
    }
  }

  Future<void> _onSigninWithGoogleRequested(
    SigninWithGoogleRequested event,
    Emitter<SigninState> emit,
  ) async {
    emit(SigninLoading());

    try {
      final response = await apiService.signInWithGoogle();

      if (response == null) {
        emit(SigninInitial());
      } else if (response.success) {
        emit(SigninSuccess(response.data!));
      } else {
        emit(SigninFailure(response.message));
      }
    } catch (_) {
      // The page shows its own message: Google's errors are not for users.
      emit(const SigninFailure());
    }
  }
}
