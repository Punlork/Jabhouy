part of 'signin_bloc.dart';

abstract class SigninState extends Equatable {
  const SigninState();

  @override
  List<Object?> get props => [];
}

class SigninInitial extends SigninState {}

class SigninLoading extends SigninState {}

class SigninSuccess extends SigninState {
  const SigninSuccess(this.user);
  final User user;
}

class SigninFailure extends SigninState {
  const SigninFailure([this.error]);

  /// Null when the page should show a generic message.
  final String? error;

  @override
  List<Object?> get props => [error];
}
