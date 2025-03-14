import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:my_app/app/app.dart';
import 'package:my_app/profile/profile.dart';

part 'profile_event.dart';
part 'profile_state.dart';

extension ProfileStateExtension on ProfileState {
  ProfileStateData? get asLoaded => this is ProfileStateData ? this as ProfileStateData : null;
}

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  ProfileBloc(
    this.upload,
    this._service,
  ) : super(const ProfileStateData(isSuccess: false)) {
    on<UpdateProfile>(_onUpdateProfile);
    on<ResetProfile>(_onReset);
  }

  final UploadBloc upload;
  final ProfileService _service;

  Future<void> _onUpdateProfile(
    UpdateProfile event,
    Emitter<ProfileState> emit,
  ) async {
    LoadingOverlay.show();

    try {
      final response = await _service.editProfile(
        User(
          name: event.name,
          image: event.image  ,
        ),
      );

      if (!response.success) return;

      emit(ProfileStateData(isSuccess: response.data ?? false));
    } catch (e) {
      showErrorSnackBar(null, 'Failed to update item: $e');
    }
  }

  void _onReset(
    ResetProfile event,
    Emitter<ProfileState> emit,
  ) =>
      emit(const ProfileStateData(isSuccess: false));
}
