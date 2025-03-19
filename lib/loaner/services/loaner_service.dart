import 'package:my_app/app/app.dart';
import 'package:my_app/loaner/loaner.dart';

class LoanerService extends BaseService {
  LoanerService(super.apiService);

  @override
  String get basePath => '/loans';

  Future<ApiResponse<List<LoanerModel>>> getLoaners({
    int page = 1,
    int pageSize = 10,
    String searchQuery = '',
    String categoryFilter = '',
  }) {
    return get(
      '',
      queryParameters: {
        'page': page.toString(),
        'pageSize': pageSize.toString(),
        'search': searchQuery,
        'category': categoryFilter,
      }..removeWhere(
          (key, value) => value.toString().isEmpty,
        ),
      parser: (value) {
        if (value is List) {
          return value
              .map<LoanerModel>(
                (json) => LoanerModel.fromJson(json as Map<String, dynamic>),
              )
              .toList();
        }
        return <LoanerModel>[];
      },
    );
  }

  Future<ApiResponse<LoanerModel?>> createLoaner(LoanerModel body) => post(
        '',
        bodyParser: body.toJson,
        parser: (value) => value is Map
            ? LoanerModel.fromJson(
                value as Map<String, dynamic>,
              )
            : null,
      );

  Future<ApiResponse<LoanerModel?>> updateLoaner(LoanerModel body) => put(
        '/${body.id}',
        bodyParser: body.toJson,
        parser: (value) => value is Map
            ? LoanerModel.fromJson(
                value as Map<String, dynamic>,
              )
            : null,
      );

  Future<ApiResponse<dynamic>> deleteLoaner(LoanerModel body) => delete(
        '/${body.id}',
      );
}
