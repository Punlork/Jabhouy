part of 'auth_bloc.dart';

@immutable
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class Authenticated extends AuthState {
  const Authenticated(
    this.user, {
    this.isOffline = false,
    this.isSessionTrusted = true,
  });

  final User user;
  final bool isOffline;
  final bool isSessionTrusted;

  @override
  List<Object?> get props => [user, isOffline, isSessionTrusted];
}

class Unauthenticated extends AuthState {
  const Unauthenticated({this.sessionExpired = false});

  /// The server rejected a saved session after the app had opened on it,
  /// rather than the user signing out.
  final bool sessionExpired;

  @override
  List<Object?> get props => [sessionExpired];
}
