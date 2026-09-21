import 'package:jabhouy/app/app.dart';
import 'package:jabhouy/customer/customer.dart';
import 'package:jabhouy_core/jabhouy_core.dart';

/// Every HTTP call the customer feature makes, and nothing else.
class CustomerApi extends BaseService {
  CustomerApi(super.apiService);

  @override
  String get basePath => '/customers';

  Future<Result<PaginatedResponse<CustomerModel>>> fetchCustomers({
    int page = 1,
    int limit = 10,
    String searchQuery = '',
    String categoryFilter = '',
  }) async {
    final response = await get<PaginatedResponse<CustomerModel>>(
      '',
      queryParameters: {
        'page': page.toString(),
        'limit': limit.toString(),
        'name': searchQuery,
        'category': categoryFilter,
      }..removeWhere((key, value) => value.toString().isEmpty),
      parser: (value) => value is Map
          ? PaginatedResponse.fromJson(
              value as Map<String, dynamic>,
              CustomerModel.fromJson,
            )
          : PaginatedResponse(items: [], pagination: Pagination()),
    );
    return response.toResult();
  }

  Future<Result<CustomerModel>> createCustomer(CustomerModel body) async {
    final response = await post<CustomerModel>(
      '',
      bodyParser: body.toJson,
      parser: _parse,
    );
    return response.toResult();
  }

  Future<Result<CustomerModel>> updateCustomer(CustomerModel body) async {
    final response = await put<CustomerModel>(
      '/${body.id}',
      bodyParser: body.toJson,
      parser: _parse,
    );
    return response.toResult();
  }

  Future<Result<void>> deleteCustomer(int id) async {
    final response = await delete<dynamic>('/$id');
    return response.toVoidResult();
  }

  CustomerModel _parse(dynamic value) {
    return CustomerModel.fromJson(value as Map<String, dynamic>);
  }
}
