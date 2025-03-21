import 'package:my_app/app/app.dart';
import 'package:my_app/customer/customer.dart';

class CustomerService extends BaseService {
  CustomerService(super.apiService);

  @override
  String get basePath => '/customers';

  Future<ApiResponse<PaginatedResponse<CustomerModel>>> getCustomers({
    int? page = 1,
    int? limit = 10,
    String searchQuery = '',
    String categoryFilter = '',
  }) =>
      get(
        '',
        queryParameters: {
          'page': page.toString(),
          'limit': limit.toString(),
          'name': searchQuery,
          'category': categoryFilter,
        }..removeWhere(
            (key, value) => value.toString().isEmpty,
          ),
        parser: (value) => value is Map
            ? PaginatedResponse.fromJson(
                value as Map<String, dynamic>,
                CustomerModel.fromJson,
              )
            : PaginatedResponse(
                items: [],
                pagination: Pagination(),
              ),
      );

  Future<ApiResponse<CustomerModel?>> createCustomer(CustomerModel body) => post(
        '',
        bodyParser: body.toJson,
        parser: (value) => value is Map
            ? CustomerModel.fromJson(
                value as Map<String, dynamic>,
              )
            : null,
      );

  Future<ApiResponse<CustomerModel?>> updateCustomer(CustomerModel body) => put(
        '/${body.id}',
        bodyParser: body.toJson,
        parser: (value) => value is Map
            ? CustomerModel.fromJson(
                value as Map<String, dynamic>,
              )
            : null,
      );

  Future<ApiResponse<dynamic>> deleteCustomer(CustomerModel body) => delete(
        '/${body.id}',
      );
}
