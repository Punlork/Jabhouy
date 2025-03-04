part of 'signup_bloc.dart';

abstract class SignupState extends Equatable {
  const SignupState();

  @override
  List<Object?> get props => [];
}

class SignupInitial extends SignupState {}

class SignupLoading extends SignupState {}

class SignupSuccess extends SignupState {
  const SignupSuccess(this.user);
  final User user;
}

class SignupFailure extends SignupState {
  const SignupFailure(this.error);
  final String error;

  @override
  List<Object?> get props => [error];
}
