import 'package:jabhouy/app/app.dart';
import 'package:jabhouy/customer/customer.dart';

/// Every HTTP call the customer feature makes, and nothing else.
class CustomerApi extends BaseService {
  CustomerApi(super.apiService);

  @override
  String get basePath => '/customers';

  Future<ApiResponse<PaginatedResponse<CustomerModel>>> fetchCustomers({
    int page = 1,
    int limit = 10,
    String searchQuery = '',
    String categoryFilter = '',
  }) {
    return get<PaginatedResponse<CustomerModel>>(
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
  }

  Future<ApiResponse<CustomerModel?>> createCustomer(CustomerModel body) {
    return post('', bodyParser: body.toJson, parser: _parse);
  }

  Future<ApiResponse<CustomerModel?>> updateCustomer(CustomerModel body) {
    return put('/${body.id}', bodyParser: body.toJson, parser: _parse);
  }

  Future<ApiResponse<dynamic>> deleteCustomer(int id) {
    return delete<dynamic>('/$id');
  }

  CustomerModel? _parse(dynamic value) {
    return value is Map
        ? CustomerModel.fromJson(value as Map<String, dynamic>)
        : null;
  }
}
