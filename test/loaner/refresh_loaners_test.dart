// The one use case loaner earns. It is tested against two mocked
// repositories rather than a database, because the only thing it does is
// decide what to hand to whom — the storage behaviour belongs to the DAO
// tests either side of it.
import 'package:flutter_test/flutter_test.dart';
import 'package:jabhouy/app/app.dart';
import 'package:jabhouy/customer/customer.dart';
import 'package:jabhouy/loaner/loaner.dart';
import 'package:jabhouy_core/jabhouy_core.dart';
import 'package:mocktail/mocktail.dart';

class MockLoanerRepository extends Mock implements LoanerRepository {}

class MockCustomerRepository extends Mock implements CustomerRepository {}

void main() {
  late MockLoanerRepository loaners;
  late MockCustomerRepository customers;
  late RefreshLoanersUseCase refreshLoaners;

  setUpAll(() {
    registerFallbackValue(<CustomerModel>[]);
  });

  setUp(() {
    loaners = MockLoanerRepository();
    customers = MockCustomerRepository();
    refreshLoaners = RefreshLoanersUseCase(loaners, customers);
    when(() => customers.cacheCustomers(any())).thenAnswer((_) async {});
  });

  ApiResponse<PaginatedResponse<LoanerModel>> page(List<LoanerModel> items) {
    return ApiResponse(
      success: true,
      data: PaginatedResponse<LoanerModel>(
        items: items,
        pagination: Pagination(total: items.length, totalPage: 1),
      ),
    );
  }

  void serverReturns(ApiResponse<PaginatedResponse<LoanerModel>> response) {
    when(
      () => loaners.refreshLoaners(
        page: any(named: 'page'),
        limit: any(named: 'limit'),
        searchQuery: any(named: 'searchQuery'),
        customer: any(named: 'customer'),
        fromDate: any(named: 'fromDate'),
        toDate: any(named: 'toDate'),
      ),
    ).thenAnswer((_) async => response);
  }

  test('embedded customers are cached through the customer repository',
      () async {
    serverReturns(
      page([
        LoanerModel(
          id: 1,
          amount: 500,
          customer: const CustomerModel(id: 12, name: 'Dara'),
        ),
        LoanerModel(
          id: 2,
          amount: 700,
          customer: const CustomerModel(id: 13, name: 'Sophea'),
        ),
      ]),
    );

    await refreshLoaners();

    final captured = verify(() => customers.cacheCustomers(captureAny()))
        .captured
        .single as List<CustomerModel>;
    expect(captured.map((c) => c.id), unorderedEquals([12, 13]));
  });

  test('one customer on two loans is cached once', () async {
    serverReturns(
      page([
        LoanerModel(
          id: 1,
          amount: 500,
          customer: const CustomerModel(id: 12, name: 'Dara'),
        ),
        LoanerModel(
          id: 2,
          amount: 700,
          customer: const CustomerModel(id: 12, name: 'Dara'),
        ),
      ]),
    );

    await refreshLoaners();

    final captured = verify(() => customers.cacheCustomers(captureAny()))
        .captured
        .single as List<CustomerModel>;
    expect(captured, hasLength(1));
  });

  test('a refresh that failed caches nothing', () async {
    serverReturns(
      ApiResponse(success: false, message: 'Offline - showing cached loaners.'),
    );

    final response = await refreshLoaners();

    expect(response.success, isFalse);
    verifyNever(() => customers.cacheCustomers(any()));
  });

  test('loans with no customer attached cache nothing', () async {
    serverReturns(page([LoanerModel(id: 1, amount: 500)]));

    await refreshLoaners();

    verifyNever(() => customers.cacheCustomers(any()));
  });
}
