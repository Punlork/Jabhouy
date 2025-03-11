part of 'upload_bloc.dart';

abstract class UploadEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class SelectImageEvent extends UploadEvent {
  SelectImageEvent(this.source);
  final ImageSource source;

  @override
  List<Object?> get props => [source];
}

class UploadImageEvent extends UploadEvent {
  UploadImageEvent(this.image);
  final File image;

  @override
  List<Object?> get props => [image];
}

class ClearImageEvent extends UploadEvent {
  @override
  List<Object?> get props => [];
}
