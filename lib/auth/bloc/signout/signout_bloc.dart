import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:my_app/auth/auth.dart';

part 'signout_event.dart';
part 'signout_state.dart';

class SignoutBloc extends Bloc<SignoutEvent, SignoutState> {
  SignoutBloc(this.apiService) : super(SignoutInitial()) {
    on<SignoutSubmitted>(_onSignoutSubmitted);
  }

  final AuthService apiService;

  Future<void> _onSignoutSubmitted(
    SignoutSubmitted event,
    Emitter<SignoutState> emit,
  ) async {
    emit(SignoutLoading());

    try {
      final response = await apiService.signout();

      if (response.success) {
        emit(SignoutSuccess(response.data!));
      } else {
        emit(SignoutFailure(response.message ?? 'Unknown error'));
      }
    } catch (e) {
      emit(SignoutFailure(e.toString()));
    }
  }
}
