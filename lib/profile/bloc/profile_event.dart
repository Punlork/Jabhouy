part of 'profile_bloc.dart';

abstract class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object?> get props => [];
}

class UpdateProfile extends ProfileEvent {
  const UpdateProfile({this.name, this.image});

  final String? name;
  final String? image;

  @override
  List<Object?> get props => [name, image];
}

class ResetProfile extends ProfileEvent {}
