part of 'signout_bloc.dart';

@immutable
abstract class SignoutState extends Equatable {
  const SignoutState();

  @override
  List<Object?> get props => [];
}

class SignoutInitial extends SignoutState {}

class SignoutLoading extends SignoutState {}

class SignoutSuccess extends SignoutState {}

class SignoutFailure extends SignoutState {
  const SignoutFailure(this.error);
  final String error;

  @override
  List<Object?> get props => [error];
}
