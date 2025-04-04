import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:my_app/l10n/l10n.dart';
import 'package:path_provider/path_provider.dart';
import 'package:super_clipboard/super_clipboard.dart';

mixin ClipboardImageMixin<T extends StatefulWidget> on State<T> {
  DateTime? _lastClipboardCheck;
  static const int _coolDownSeconds = 5;

  void registerClipboardObserver() {
    WidgetsBinding.instance.addObserver(_ClipboardObserver(this));
  }

  void unregisterClipboardObserver() {
    WidgetsBinding.instance.removeObserver(_ClipboardObserver(this));
  }

  Future<void> _checkClipboardForImage() async {
    final now = DateTime.now();
    if (_lastClipboardCheck != null && now.difference(_lastClipboardCheck!).inSeconds < _coolDownSeconds) {
      return;
    }
    _lastClipboardCheck = now;

    try {
      final clipboard = SystemClipboard.instance;
      if (clipboard == null) return;

      final reader = await clipboard.read();
      final file = await _getFileFromReader(reader);
      if (file != null && mounted) {
        onImageFound(file);
      }
    } catch (e) {
      // logger.i('Error accessing clipboard: $e');
    }
  }

  Future<void> forceCheckClipboardForImage() async {
    try {
      final clipboard = SystemClipboard.instance;
      if (clipboard == null) return;

      final reader = await clipboard.read();
      final file = await _getFileFromReader(reader);
      if (file != null && mounted) {
        onImageFound(file);
      }
    } catch (e) {
      // logger.i('Error accessing clipboard: $e');
    }
  }

  Future<File?> _getFileFromReader(ClipboardReader reader) async {
    final completer = Completer<File?>();

    Future<void> processFile(DataReaderFile file, String extension) async {
      final stream = file.getStream();
      final bytes = await _streamToBytes(stream);
      if (bytes != null) {
        final tempDir = await getTemporaryDirectory();
        final tempFile = File('${tempDir.path}/clipboard_image.$extension');
        await tempFile.writeAsBytes(bytes);
        completer.complete(tempFile);
      } else {
        completer.complete(null);
      }
    }

    if (reader.canProvide(Formats.png)) {
      reader.getFile(
        Formats.png,
        (file) async {
          await processFile(file, 'png');
        },
      );
    } else if (reader.canProvide(Formats.jpeg)) {
      reader.getFile(
        Formats.jpeg,
        (file) async {
          await processFile(file, 'jpg');
        },
      );
    } else {
      completer.complete(null);
    }

    return completer.future;
  }

  Future<Uint8List?> _streamToBytes(Stream<Uint8List> stream) async {
    final bytes = <int>[];
    await for (final chunk in stream) {
      bytes.addAll(chunk);
    }
    return bytes.isNotEmpty ? Uint8List.fromList(bytes) : null;
  }

  void showImagePreviewSnackBar(File file) {
    final snackBar = SnackBar(
      duration: const Duration(seconds: 5),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      backgroundColor: Colors.white,
      margin: const EdgeInsets.all(16),
      content: GestureDetector(
        onTap: () => onImageSelected(file),
        child: StatefulBuilder(
          builder: (context, setState) => Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.file(
                  file,
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.error),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  context.l10n.imgFound,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
      ),
      action: SnackBarAction(
        label: context.l10n.cancel,
        onPressed: () {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
        },
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  Future<void> pasteImage() async {
    try {
      final clipboard = SystemClipboard.instance;
      if (clipboard == null) {
        if (mounted) {
          _showErrorSnackBar('Clipboard not available');
        }
        return;
      }

      final reader = await clipboard.read();
      final file = await _getFileFromReader(reader);
      if (file != null && mounted) {
        onImageSelected(file);
      } else if (mounted) {
        _showErrorSnackBar('No image found in clipboard');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Error accessing clipboard: $e');
      }
    }
  }

  void onImageFound(File file);
  void onImageSelected(File file);

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }
}

class _ClipboardObserver extends WidgetsBindingObserver {
  _ClipboardObserver(this._mixin);
  final ClipboardImageMixin _mixin;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _mixin._checkClipboardForImage();
    }
  }
}
