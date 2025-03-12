import 'dart:io';

import 'package:my_app/app/app.dart';

class UploadService extends BaseService {
  UploadService(super.apiService);

  @override
  String get basePath => '/upload';

  Future<ApiResponse<String?>> upload({
    required File file,
    required String fileName,
  }) async =>
      post(
        '',
        imageFile: file,
        imageFieldName: fileName,
        parser: (value) => value is Map ? value['url'].toString() : null,
      );
}
