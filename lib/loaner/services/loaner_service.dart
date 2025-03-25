import 'package:my_app/app/app.dart';
import 'package:my_app/loaner/loaner.dart';

class LoanerService extends BaseService {
  LoanerService(super.apiService);

  @override
  String get basePath => '/loans';

  String _formatToRFC3339Date(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<ApiResponse<PaginatedResponse<LoanerModel>>> getLoaners({
    int page = 1,
    int limit = 10,
    String searchQuery = '',
    String? customer,
    DateTime? toDate,
    DateTime? fromDate,
  }) =>
      get(
        '',
        queryParameters: {
          'page': page.toString(),
          'limit': limit.toString(),
          'name': searchQuery,
          'customer': customer,
          'to': toDate != null ? _formatToRFC3339Date(toDate) : null,
          'from': fromDate != null ? _formatToRFC3339Date(fromDate) : null,
        }..removeWhere(
            (key, value) => value.toString().isEmpty || value == null,
          ),
        parser: (value) => value is Map
            ? PaginatedResponse.fromJson(
                value as Map<String, dynamic>,
                LoanerModel.fromJson,
              )
            : PaginatedResponse(
                items: [],
                pagination: Pagination(),
              ),
      );

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
