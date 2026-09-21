import 'package:jabhouy/app/app.dart';
import 'package:jabhouy/customer/customer.dart';
import 'package:jabhouy/loaner/loaner.dart';
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
/// Known gap: this file imports `app.dart` for `ApiResponse`, which pulls
/// Flutter in transitively, so the doc's "no Flutter in `logic/`" rule is
/// not yet enforced here. It becomes enforceable when `Result<T>` moves
/// into `jabhouy_core` — the one core primitive from the doc's table that
/// is still outstanding.
class RefreshLoanersUseCase {
  const RefreshLoanersUseCase(this._loaners, this._customers);

  final LoanerRepository _loaners;
  final CustomerRepository _customers;

  Future<ApiResponse<PaginatedResponse<LoanerModel>>> call({
    int page = 1,
    int limit = 10,
    String searchQuery = '',
    String? customer,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    final response = await _loaners.refreshLoaners(
      page: page,
      limit: limit,
      searchQuery: searchQuery,
      customer: customer,
      fromDate: fromDate,
      toDate: toDate,
    );

    final data = response.data;
    if (!response.success || data == null) return response;

    // Last one wins per id, which is what the old batch insert did.
    final embedded = <int, CustomerModel>{};
    for (final loaner in data.items) {
      final c = loaner.customer;
      if (c != null) embedded[c.id] = c;
    }

    if (embedded.isNotEmpty) {
      await _customers.cacheCustomers(embedded.values.toList());
    }

    return response;
  }
}
