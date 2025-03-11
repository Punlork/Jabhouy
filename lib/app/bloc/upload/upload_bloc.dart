import 'dart:async';
import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:my_app/app/app.dart';
import 'package:my_app/l10n/l10n.dart';

part 'upload_event.dart';
part 'upload_state.dart';

class UploadBloc extends Bloc<UploadEvent, UploadState> {
  UploadBloc() : super(const UploadInitial()) {
    on<SelectImageEvent>(_onSelectImage);
    on<UploadImageEvent>(_onUploadImage);
    on<ClearImageEvent>(_onClearImage);
  }

  File? _selectedImage;

  File? get selectedImage => _selectedImage;

  Future<void> _onSelectImage(SelectImageEvent event, Emitter<UploadState> emit) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: event.source);
    if (pickedFile != null) {
      _selectedImage = File(pickedFile.path);
      emit(UploadImageSelected(_selectedImage!));
    }
  }

  Future<void> _onUploadImage(UploadImageEvent event, Emitter<UploadState> emit) async {
    // emit(const UploadInProgress());
    LoadingOverlay.show();
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      emit(const UploadSuccess('imageUrl'));
      LoadingOverlay.hide();

      // final imageUrl = await _uploadImageToServer(event.image); // Implement this in subclasses
      // emit(UploadSuccess(imageUrl));
    } catch (e) {
      emit(UploadFailure(e.toString()));
    }
  }

  Future<void> _onClearImage(ClearImageEvent event, Emitter<UploadState> emit) async {
    _selectedImage = null;
    emit(const UploadInitial());
  }

  void showImageSourceDialog(
    BuildContext context, {
    VoidCallback? onTakePhoto,
    VoidCallback? onChoseFromGallery,
  }) {
    final l10n = AppLocalizations.of(context);
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.selectImageSource, style: AppTextTheme.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text(l10n.takePhoto, style: AppTextTheme.body),
              onTap: () {
                Navigator.pop(context);
                onTakePhoto?.call();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(l10n.chooseFromGallery, style: AppTextTheme.body),
              onTap: () {
                Navigator.pop(context);
                onChoseFromGallery?.call();
              },
            ),
          ],
        ),
      ),
    );
  }

  // Future<String> _uploadImageToServer(File image);
}
