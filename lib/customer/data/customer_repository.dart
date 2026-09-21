import 'package:jabhouy/app/app.dart';
import 'package:jabhouy/customer/customer.dart';

/// The seam the customer bloc talks to.
///
/// Customer earns no `logic/` layer: it holds a name and nothing decides
/// anything about it.
abstract class CustomerRepository {
  Stream<List<CustomerModel>> watchCustomers();

  Future<bool> hasCachedCustomers();

  Future<ApiResponse<PaginatedResponse<CustomerModel>>> refreshCustomers({
    int page,
    int limit,
    String searchQuery,
    String categoryFilter,
  });

  Future<ApiResponse<CustomerModel?>> createCustomer(CustomerModel body);

  Future<ApiResponse<CustomerModel?>> updateCustomer(CustomerModel body);

  Future<ApiResponse<dynamic>> deleteCustomer(CustomerModel body);

  Future<void> syncPendingChanges();
}
