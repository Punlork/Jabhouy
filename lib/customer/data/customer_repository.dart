import 'package:jabhouy/app/app.dart';
import 'package:jabhouy/customer/customer.dart';
import 'package:jabhouy_core/jabhouy_core.dart';

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

  /// Writes customers another feature already fetched into the cache.
  ///
  /// A loan response carries its customer embedded. Caching it belongs to
  /// customer, so `RefreshLoanersUseCase` comes through here rather than
  /// letting the loaner repository write the `Customers` table.
  Future<void> cacheCustomers(List<CustomerModel> customers);

  Future<void> syncPendingChanges();
}
