import 'dart:io';

import 'package:jabhouy_net/jabhouy_net.dart';
import 'package:jabhouy_ui/jabhouy_ui.dart';

/// Satisfies `jabhouy_ui`'s [ImageUploader] port with `jabhouy_net`.
///
/// Neither package can name the other — `jabhouy_net` imports
/// `jabhouy_ui` for its snack bars, so the reverse edge would be a cycle.
/// Joining them is the app's job, which is what an app shell is for.
class UploadImageAdapter implements ImageUploader {
  const UploadImageAdapter(this._service);

  final UploadService _service;

  @override
  Future<String?> upload({
    required File file,
    required String fileName,
  }) async {
    final response = await _service.upload(file: file, fileName: fileName);
    return response.success ? response.data : null;
  }
}
