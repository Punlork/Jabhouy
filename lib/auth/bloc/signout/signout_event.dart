part of 'signout_bloc.dart';

abstract class SignoutEvent extends Equatable {
  const SignoutEvent();

  @override
  List<Object?> get props => [];
}

class SignoutSubmitted extends SignoutEvent {
  const SignoutSubmitted();

  @override
  List<Object?> get props => [];
}
