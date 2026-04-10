import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:my_app/app/app.dart';
import 'package:my_app/l10n/arb/app_localizations.dart';

class ShopItemImageSection extends StatelessWidget {
  const ShopItemImageSection({
    required this.uploadBloc,
    required this.onImageCleared,
    super.key,
  });

  final UploadBloc uploadBloc;
  final VoidCallback onImageCleared;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.image,
            style: AppTextTheme.body,
          ),
          const SizedBox(height: 8),
          BlocBuilder<UploadBloc, UploadState>(
            bloc: uploadBloc,
            builder: (context, state) {
              return Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      if (state is UploadInProgress) return;
                      uploadBloc.showImageSourceDialog(
                        context,
                        onTakePhoto: () => uploadBloc
                            .add(SelectImageEvent(ImageSource.camera)),
                        onChoseFromGallery: () => uploadBloc.add(
                          SelectImageEvent(ImageSource.gallery),
                        ),
                      );
                    },
                    icon: const Icon(Icons.upload),
                    label: Text(
                      l10n.uploadImage,
                      style: AppTextTheme.body,
                    ),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: colorScheme.onSurface,
                      backgroundColor: colorScheme.surfaceContainerHighest,
                    ),
                  ),
                  const SizedBox(width: 16),
                  switch (state) {
                    UploadImageSelected() => _SelectedImagePreview(
                        imageFile: state.selectedImage,
                        onClear: () {
                          uploadBloc.add(ClearImageEvent());
                          onImageCleared();
                        },
                      ),
                    UploadImageUrlLoaded() => _NetworkImagePreview(
                        imageUrl: state.imageUrl,
                        onClear: () {
                          uploadBloc.add(ClearImageEvent());
                          onImageCleared();
                        },
                      ),
                    _ => const SizedBox.shrink(),
                  },
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SelectedImagePreview extends StatelessWidget {
  const _SelectedImagePreview({
    required this.imageFile,
    required this.onClear,
  });

  final File imageFile;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return _PreviewFrame(
      onClear: onClear,
      child: Image.file(
        imageFile,
        width: 80,
        height: 80,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
      ),
    );
  }
}

class _NetworkImagePreview extends StatelessWidget {
  const _NetworkImagePreview({
    required this.imageUrl,
    required this.onClear,
  });

  final String imageUrl;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return _PreviewFrame(
      onClear: onClear,
      child: Image.network(
        imageUrl,
        width: 80,
        height: 80,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
      ),
    );
  }
}

class _PreviewFrame extends StatelessWidget {
  const _PreviewFrame({
    required this.child,
    required this.onClear,
  });

  final Widget child;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: child,
        ),
        Positioned(
          top: 5,
          right: 5,
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: colorScheme.scrim.withValues(alpha: 0.55),
              shape: BoxShape.circle,
            ),
            child: GestureDetector(
              onTap: onClear,
              child: const Icon(
                Icons.close,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
