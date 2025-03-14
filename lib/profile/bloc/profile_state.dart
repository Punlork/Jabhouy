part of 'profile_bloc.dart';

abstract class ProfileState extends Equatable {
  const ProfileState();
}

class ProfileStateData extends ProfileState {
  const ProfileStateData({required this.isSuccess});

  final bool isSuccess;

  @override
  List<Object?> get props => [isSuccess];
} 
