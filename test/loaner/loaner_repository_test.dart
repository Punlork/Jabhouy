// The loaner slice — the last of the four, and the mirror of shop and
// category one table down: Loaners.customerId references Customers.id the
// way ShopItems.categoryId references Categories.id.
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jabhouy/app/app.dart';
import 'package:jabhouy/customer/customer.dart';
import 'package:jabhouy/loaner/loaner.dart';
import 'package:jabhouy_core/jabhouy_core.dart';
import 'package:jabhouy_sync/jabhouy_sync.dart';
import 'package:mocktail/mocktail.dart';

class MockLoanerApi extends Mock implements LoanerApi {}

class MockCustomerApi extends Mock implements CustomerApi {}

class MockConnectivityService extends Mock implements ConnectivityService {}

void main() {
  late AppDatabase db;
  late LoanerDao dao;
  late CustomerDao customerDao;
  late MockLoanerApi api;
  late MockCustomerApi customerApi;
  late MockConnectivityService connectivity;
  late SyncEngine engine;
  late DefaultLoanerRepository repository;

  setUpAll(() {
    registerFallbackValue(LoanerModel(id: 0, amount: 0));
    registerFallbackValue(const CustomerModel(id: 0, name: 'fallback'));
  });

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    dao = LoanerDao(db);
    customerDao = CustomerDao(db);
    api = MockLoanerApi();
    customerApi = MockCustomerApi();
    connectivity = MockConnectivityService();
    engine = SyncEngine(
      database: db,
      transport: AppSyncTransport([
        LoanerSyncAdapter(dao, api),
        CustomerSyncAdapter(customerDao, customerApi),
      ]),
    );
    repository = DefaultLoanerRepository(dao, api, engine, connectivity);
  });

  tearDown(() async {
    await db.close();
  });

  void goOnline() {
    when(() => connectivity.isOnline).thenAnswer((_) async => true);
  }

  void goOffline() {
    when(() => connectivity.isOnline).thenAnswer((_) async => false);
  }

  Future<List<Loaner>> rows() => db.select(db.loaners).get();
  Future<List<OutboxEntry>> jobs() => db.select(db.outboxEntries).get();

  test('a create made offline is queued locally and nothing is pushed',
      () async {
    goOffline();

    await repository.createLoaner(LoanerModel(id: 0, amount: 500));

    final saved = (await rows()).single;
    expect(saved.amount, 500);
    expect(saved.id, lessThan(0));
    expect(saved.syncStatus, SyncStatus.pending);

    final job = (await jobs()).single;
    expect(job.entityType, SyncEntityType.loaner);
    expect(job.operation, SyncOperation.create);
    verifyNever(() => api.createLoaner(any()));
  });

  test('a loan saved with a customer attached survives the round trip',
      () async {
    // Regression. Loaners.customer is a denormalised JSON blob, and the
    // encoder wrote the raw syncStatus into it. That was an int until
    // c391ebb made it an enum, at which point jsonEncode threw
    // JsonUnsupportedObjectError and every loan with a customer failed to
    // save at all.
    goOffline();

    await repository.createLoaner(
      LoanerModel(
        id: 0,
        amount: 500,
        customerId: 12,
        customer: const CustomerModel(id: 12, name: 'Dara'),
      ),
    );

    final saved = (await rows()).single;
    expect(saved.customer, isNotNull);

    final decoded = decodeCustomer(saved.customer);
    expect(decoded?.id, 12);
    expect(decoded?.name, 'Dara');
    expect(decoded?.syncStatus, SyncStatus.synced);
  });

  test('a loan never reaches the server before its offline customer',
      () async {
    // Enqueued in the wrong order on purpose, as in the category test.
    const customerLocalId = -999;
    const loanerLocalId = -70;

    await customerDao.insertPending(
      const CustomerModel(id: customerLocalId, name: 'Dara'),
    );
    await dao.insertPending(
      LoanerModel(id: loanerLocalId, amount: 500, customerId: customerLocalId),
    );

    await engine.enqueue(
      entityType: SyncEntityType.loaner,
      localId: '$loanerLocalId',
      operation: SyncOperation.create,
      idempotencyKey: 'loaner:$loanerLocalId:create',
      dependsOnLocalId: '$customerLocalId',
    );
    await engine.enqueue(
      entityType: SyncEntityType.customer,
      localId: '$customerLocalId',
      operation: SyncOperation.create,
      idempotencyKey: 'customer:$customerLocalId:create',
    );

    when(() => customerApi.createCustomer(any())).thenAnswer(
      (i) async => ApiResponse(
        success: true,
        data: (i.positionalArguments.first as CustomerModel).copyWith(id: 12),
      ),
    );
    when(() => api.createLoaner(any())).thenAnswer(
      (i) async => ApiResponse(
        success: true,
        data: (i.positionalArguments.first as LoanerModel).copyWith(id: 88),
      ),
    );

    await engine.drain();

    verifyInOrder([
      () => customerApi.createCustomer(any()),
      () => api.createLoaner(any()),
    ]);

    final loan = (await rows()).single;
    expect(loan.id, 88);
    expect(
      loan.customerId,
      12,
      reason: 'pushed with the server customer id, not the local one',
    );
    expect(await jobs(), isEmpty);
  });

  test('a delete the server has already forgotten counts as done', () async {
    goOnline();
    await dao.cacheServerLoaners([LoanerModel(id: 6, amount: 500)]);
    when(() => api.deleteLoaner(6)).thenAnswer(
      (_) async => ApiResponse<dynamic>(success: false, statusCode: 404),
    );

    await repository.deleteLoaner(LoanerModel(id: 6, amount: 500));

    expect(await rows(), isEmpty);
    expect(await jobs(), isEmpty);
  });

  test('a 400 stops the job and marks the row failed', () async {
    goOnline();
    when(() => api.createLoaner(any())).thenAnswer(
      (_) async => ApiResponse(
        success: false,
        message: 'amount must be positive',
        statusCode: 400,
      ),
    );

    await repository.createLoaner(LoanerModel(id: 0, amount: -1));

    expect((await rows()).single.syncStatus, SyncStatus.failed);
    expect(
      (await jobs()).single.lastError,
      contains('amount must be positive'),
    );
  });
}
