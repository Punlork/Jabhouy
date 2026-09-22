import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:jabhouy_l10n/jabhouy_l10n.dart';
import 'package:jabhouy_ui/src/theme/text_theme.dart';
import 'package:jabhouy_ui/src/upload/image_uploader.dart';
import 'package:jabhouy_ui/src/utils/overlay_loading.dart';

part 'upload_event.dart';
part 'upload_state.dart';

class UploadBloc extends Bloc<UploadEvent, UploadState> {
  UploadBloc(this._service) : super(const UploadInitial()) {
    on<SelectImageEvent>(_onSelectImage);
    on<UploadImageEvent>(_onUploadImage);
    on<ClearImageEvent>(_onClearImage);
    on<LoadExistingImageEvent>(_onLoadExistingImage);
    on<SelectUiImageEvent>(
      (event, emit) {
        _selectedImage = event.image;
        emit(UploadImageSelected(_selectedImage!));
      },
    );
  }

  final ImageUploader _service;

  File? _selectedImage;

  File? get selectedImage => _selectedImage;

  Future<void> _onLoadExistingImage(
    LoadExistingImageEvent event,
    Emitter<UploadState> emit,
  ) async {
    if (event.imageUrl != null && event.imageUrl!.isNotEmpty) {}
    emit(UploadImageUrlLoaded(event.imageUrl!));
  }

  Future<void> _onSelectImage(
    SelectImageEvent event,
    Emitter<UploadState> emit,
  ) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: event.source);
    if (pickedFile != null) {
      _selectedImage = File(pickedFile.path);
      emit(UploadImageSelected(_selectedImage!));
    }
  }

  Future<void> _onUploadImage(
    UploadImageEvent event,
    Emitter<UploadState> emit,
  ) async {
    LoadingOverlay.show();
    emit(const UploadInProgress());
    try {
      final url = await _service.upload(
        file: event.image,
        fileName: 'image',
      );
      if (url != null) {
        emit(UploadSuccess(url));
      }
    } catch (e) {
      emit(UploadFailure(e.toString()));
    }
  }

  Future<void> _onClearImage(
    ClearImageEvent event,
    Emitter<UploadState> emit,
  ) async {
    _selectedImage = null;
    emit(const UploadInitial());
  }

  void showImageSourceDialog(
    BuildContext context, {
    VoidCallback? onTakePhoto,
    VoidCallback? onChoseFromGallery,
  }) {
    final l10n = context.l10n;
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
