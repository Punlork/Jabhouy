import 'dart:io';

import 'package:jabhouy_net/src/api_service.dart';
import 'package:jabhouy_net/src/base_service.dart';

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
