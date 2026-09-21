import 'package:jabhouy/customer/models/customer_model.dart';
import 'package:jabhouy/loaner/models/loaner_model.dart';
import 'package:jabhouy_core/jabhouy_core.dart';

/// The seam the loaner bloc and `RefreshLoanersUseCase` talk to.
///
/// Imports no Flutter. That is load-bearing rather than tidy: `logic/`
/// may not import Flutter, and a use case cannot depend on a repository
/// that does.
abstract class LoanerRepository {
  Stream<List<LoanerModel>> watchLoaners({
    String searchQuery,
    CustomerModel? customerFilter,
    DateTime? fromDate,
    DateTime? toDate,
  });

  Future<bool> hasCachedLoaners({
    String searchQuery,
    CustomerModel? customerFilter,
    DateTime? fromDate,
    DateTime? toDate,
  });

  /// Pulls a page from the server and caches the loaners.
  ///
  /// It deliberately does not touch the customer cache, although the
  /// response carries embedded customers. Writing another feature's table
  /// from here is what gave the old service its reach;
  /// `RefreshLoanersUseCase` does that half through `CustomerRepository`.
  Future<Result<PaginatedResponse<LoanerModel>>> refreshLoaners({
    int page,
    int limit,
    String searchQuery,
    String? customer,
    DateTime? fromDate,
    DateTime? toDate,
  });

  Future<Result<LoanerModel>> createLoaner(LoanerModel body);

  Future<Result<LoanerModel>> updateLoaner(LoanerModel body);

  Future<Result<void>> deleteLoaner(LoanerModel body);

  Future<void> syncPendingChanges();
}
