import 'package:jabhouy/app/app.dart';
import 'package:jabhouy/loaner/loaner.dart';
import 'package:jabhouy_core/jabhouy_core.dart';

/// Every HTTP call the loaner feature makes, and nothing else.
class LoanerApi extends BaseService {
  LoanerApi(super.apiService);

  @override
  String get basePath => '/loans';

  Future<Result<PaginatedResponse<LoanerModel>>> fetchLoaners({
    int page = 1,
    int limit = 10,
    String searchQuery = '',
    String? customer,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    final response = await get<PaginatedResponse<LoanerModel>>(
      '',
      queryParameters: {
        'page': page.toString(),
        'limit': limit.toString(),
        'name': searchQuery,
        'customer': customer,
        'to': toDate?.let(_rfc3339Date),
        'from': fromDate?.let(_rfc3339Date),
      }..removeWhere(
          (key, value) => value == null || value.toString().isEmpty,
        ),
      parser: (value) => value is Map
          ? PaginatedResponse.fromJson(
              value as Map<String, dynamic>,
              LoanerModel.fromJson,
            )
          : PaginatedResponse(items: [], pagination: Pagination()),
    );
    return response.toResult();
  }

  Future<Result<LoanerModel>> createLoaner(LoanerModel body) async {
    final response = await post<LoanerModel>(
      '',
      bodyParser: body.toJson,
      parser: _parse,
    );
    return response.toResult();
  }

  Future<Result<LoanerModel>> updateLoaner(LoanerModel body) async {
    final response = await put<LoanerModel>(
      '/${body.id}',
      bodyParser: body.toJson,
      parser: _parse,
    );
    return response.toResult();
  }

  Future<Result<void>> deleteLoaner(int id) async {
    final response = await delete<dynamic>('/$id');
    return response.toVoidResult();
  }

  LoanerModel _parse(dynamic value) {
    return LoanerModel.fromJson(value as Map<String, dynamic>);
  }

  String _rfc3339Date(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
