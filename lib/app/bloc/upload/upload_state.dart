part of 'upload_bloc.dart';

abstract class UploadState extends Equatable {
  const UploadState();

  @override
  List<Object> get props => [];
}

class UploadInitial extends UploadState {
  const UploadInitial();
}

class UploadImageSelected extends UploadState {
  const UploadImageSelected(this.selectedImage);
  final File selectedImage;

  @override
  List<Object> get props => [selectedImage];
}

class UploadInProgress extends UploadState {
  const UploadInProgress();
}

class UploadSuccess extends UploadState {
  const UploadSuccess(this.imageUrl);
  final String imageUrl;

  @override
  List<Object> get props => [imageUrl];
}

class UploadFailure extends UploadState {
  const UploadFailure(this.error);
  final String error;

  @override
  List<Object> get props => [error];
}

class UploadImageUrlLoaded extends UploadState {
  const UploadImageUrlLoaded(this.imageUrl);
  final String imageUrl;

  @override
  List<Object> get props => [imageUrl];
}
