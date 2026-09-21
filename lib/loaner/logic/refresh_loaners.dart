import 'package:jabhouy/customer/data/customer_repository.dart';
import 'package:jabhouy/customer/models/customer_model.dart';
import 'package:jabhouy/loaner/data/loaner_repository.dart';
import 'package:jabhouy/loaner/models/loaner_model.dart';
import 'package:jabhouy_core/jabhouy_core.dart';

/// Pulls loaners and keeps the customer cache in step.
///
/// The one use case loaner earns. Under the three conditions in
/// `docs/ARCHITECTURE_RESTRUCTURE.md` it qualifies on the first: it merges
/// two repositories. A loan response carries its customer embedded, and
/// that customer is worth caching — the autocomplete field reads it — but
/// `LoanerRepository` writing the `Customers` table directly is exactly
/// the reach that made the old services impossible to test in isolation.
///
/// Every import above is either `jabhouy_core` or a repository interface
/// or model, and none of those touch Flutter. That is checked by
/// `test/architecture/logic_layer_test.dart`, not left to review: the
/// barrels are deliberately not imported here, because a barrel exports
/// the feature's `ui` folder and would drag Flutter in with it.
class RefreshLoanersUseCase {
  const RefreshLoanersUseCase(this._loaners, this._customers);

  final LoanerRepository _loaners;
  final CustomerRepository _customers;

  Future<Result<PaginatedResponse<LoanerModel>>> call({
    int page = 1,
    int limit = 10,
    String searchQuery = '',
    String? customer,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    final result = await _loaners.refreshLoaners(
      page: page,
      limit: limit,
      searchQuery: searchQuery,
      customer: customer,
      fromDate: fromDate,
      toDate: toDate,
    );

    if (result case Ok(:final value)) {
      // Last one wins per id, which is what the old batch insert did.
      final embedded = <int, CustomerModel>{};
      for (final loaner in value.items) {
        final c = loaner.customer;
        if (c != null) embedded[c.id] = c;
      }

      if (embedded.isNotEmpty) {
        await _customers.cacheCustomers(embedded.values.toList());
      }
    }

    return result;
  }
}
