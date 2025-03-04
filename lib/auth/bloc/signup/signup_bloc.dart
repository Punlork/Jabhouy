import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:my_app/auth/auth.dart';

part 'signup_event.dart';
part 'signup_state.dart';

class SignupBloc extends Bloc<SignupEvent, SignupState> {
  SignupBloc(this.apiService) : super(SignupInitial()) {
    on<SignupSubmitted>(_onSignupSubmitted);
}

  final AuthService apiService;

  Future<void> _onSignupSubmitted(
    SignupSubmitted event,
    Emitter<SignupState> emit,
  ) async {
    emit(SignupLoading());

    try {
      final response = await apiService.signup(
        name: event.name,
        email: event.email,
        password: event.password,
      );

      if (response.success) {
        emit(SignupSuccess(response.data!));
      } else {
        emit(SignupFailure(response.message ?? 'Unknown error'));
      }
    } catch (e) {
      emit(SignupFailure(e.toString()));
    }
  }
}
