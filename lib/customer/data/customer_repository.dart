import 'package:jabhouy/customer/models/customer_model.dart';
import 'package:jabhouy_core/jabhouy_core.dart';

/// The seam the customer bloc talks to.
///
/// Customer earns no `logic/` layer: it holds a name and nothing decides
/// anything about it. Imports no Flutter, because
/// `RefreshLoanersUseCase` depends on this file and `logic/` may not.
abstract class CustomerRepository {
  Stream<List<CustomerModel>> watchCustomers();

  Future<bool> hasCachedCustomers();

  Future<Result<PaginatedResponse<CustomerModel>>> refreshCustomers({
    int page,
    int limit,
    String searchQuery,
    String categoryFilter,
  });

  Future<Result<CustomerModel>> createCustomer(CustomerModel body);

  Future<Result<CustomerModel>> updateCustomer(CustomerModel body);

  Future<Result<void>> deleteCustomer(CustomerModel body);

  /// Writes customers another feature already fetched into the cache.
  ///
  /// A loan response carries its customer embedded. Caching it belongs to
  /// customer, so `RefreshLoanersUseCase` comes through here rather than
  /// letting the loaner repository write the `Customers` table.
  Future<void> cacheCustomers(List<CustomerModel> customers);

  Future<void> syncPendingChanges();
}
