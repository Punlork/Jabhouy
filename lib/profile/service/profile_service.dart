import 'package:jabhouy/app/app.dart';
import 'package:jabhouy_net/jabhouy_net.dart';

class ProfileService extends BaseService {
  ProfileService(super.apiService);

  @override
  String get basePath => '/auth';

  Future<ApiResponse<bool>> editProfile(User user) => post(
        '/update-user',
        bodyParser: user.toJson,
        parser: (value) {
          if (value is! Map) return false;
          return value['status'].toString() == 'true';
        },
      );
}
