import 'package:jabhouy/app/app.dart';
import 'package:jabhouy/customer/customer.dart';
import 'package:jabhouy/loaner/loaner.dart';

/// The seam the loaner bloc and [RefreshLoanersUseCase] talk to.
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
  /// [RefreshLoanersUseCase] does that half through `CustomerRepository`.
  Future<ApiResponse<PaginatedResponse<LoanerModel>>> refreshLoaners({
    int page,
    int limit,
    String searchQuery,
    String? customer,
    DateTime? fromDate,
    DateTime? toDate,
  });

  Future<ApiResponse<LoanerModel?>> createLoaner(LoanerModel body);

  Future<ApiResponse<LoanerModel?>> updateLoaner(LoanerModel body);

  Future<ApiResponse<dynamic>> deleteLoaner(LoanerModel body);

  Future<void> syncPendingChanges();
}
