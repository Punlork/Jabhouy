import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:my_app/auth/auth.dart';

part 'signin_event.dart';
part 'signin_state.dart';

class SigninBloc extends Bloc<SigninEvent, SigninState> {
  SigninBloc(this.apiService) : super(SigninInitial()) {
    on<SigninSubmitted>(_onSigninSubmitted);
  }

  final AuthService apiService;

  Future<void> _onSigninSubmitted(
    SigninSubmitted event,
    Emitter<SigninState> emit,
  ) async {
    emit(SigninLoading());

    try {
      final response = await apiService.signin(
        email: event.email,
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
}
