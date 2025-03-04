part of 'auth_bloc.dart';

@immutable
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthCheckRequested extends AuthEvent {}

class AuthSignedIn extends AuthEvent {
  const AuthSignedIn(this.user);
  final User user;

  @override
  List<Object?> get props => [user];
}

class AuthSignedOut extends AuthEvent {}
