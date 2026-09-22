// The customer slice. Its reconciliation carries the same foreign-key
// repoint category's does, because Loaners.customerId references
// Customers.id -- so a customer created offline has dependents too.
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jabhouy/app/app.dart';
import 'package:jabhouy/customer/customer.dart';
import 'package:jabhouy_core/jabhouy_core.dart';
import 'package:jabhouy_net/jabhouy_net.dart';
import 'package:jabhouy_sync/jabhouy_sync.dart';
import 'package:mocktail/mocktail.dart';

class MockCustomerApi extends Mock implements CustomerApi {}

class MockConnectivityService extends Mock implements ConnectivityService {}

void main() {
  late AppDatabase db;
  late CustomerDao dao;
  late MockCustomerApi api;
  late MockConnectivityService connectivity;
  late SyncEngine engine;
  late DefaultCustomerRepository repository;

  setUpAll(() {
    registerFallbackValue(const CustomerModel(id: 0, name: 'fallback'));
  });

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    dao = CustomerDao(db);
    api = MockCustomerApi();
    connectivity = MockConnectivityService();
    engine = SyncEngine(
      database: db,
      transport: AppSyncTransport([CustomerSyncAdapter(dao, api)]),
    );
    repository = DefaultCustomerRepository(dao, api, engine, connectivity);
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

  Future<List<Customer>> rows() => db.select(db.customers).get();
  Future<List<Loaner>> loanerRows() => db.select(db.loaners).get();
  Future<List<OutboxEntry>> jobs() => db.select(db.outboxEntries).get();

  Result<CustomerModel> echo(Invocation invocation, {int? id}) {
    final sent = invocation.positionalArguments.first as CustomerModel;
    return Ok(
      sent.copyWith(id: id ?? sent.id, syncStatus: SyncStatus.synced),
    );
  }

  test('a create made offline is queued locally and nothing is pushed',
      () async {
    goOffline();

    await repository.createCustomer(const CustomerModel(id: 0, name: 'Dara'));

    final saved = (await rows()).single;
    expect(saved.name, 'Dara');
    expect(saved.id, lessThan(0));
    expect(saved.syncStatus, SyncStatus.pending);

    final job = (await jobs()).single;
    expect(job.entityType, SyncEntityType.customer);
    expect(job.operation, SyncOperation.create);
    verifyNever(() => api.createCustomer(any()));
  });

  test('reconciling a customer repoints the loaners that referenced it',
      () async {
    goOffline();
    await repository.createCustomer(const CustomerModel(id: 0, name: 'Dara'));
    final localId = (await rows()).single.id;

    await db.into(db.loaners).insert(
          LoanersCompanion.insert(
            id: const Value(-70),
            amount: 500,
            customerId: Value(localId),
            createdAt: DateTime(2026, 9, 20),
          ),
        );

    goOnline();
    when(() => api.createCustomer(any()))
        .thenAnswer((i) async => echo(i, id: 12));

    await engine.drain();

    expect((await rows()).single.id, 12);
    expect(
      (await loanerRows()).single.customerId,
      12,
      reason: 'the loaner followed its customer to the server id',
    );
    expect(await jobs(), isEmpty);
  });

  test('a delete the server has already forgotten counts as done', () async {
    goOnline();
    await dao.cacheServerCustomers([const CustomerModel(id: 5, name: 'Dara')]);
    when(() => api.deleteCustomer(5)).thenAnswer(
      (_) async => const Err(AppException('gone', statusCode: 404)),
    );

    await repository.deleteCustomer(const CustomerModel(id: 5, name: 'Dara'));

    expect(await rows(), isEmpty);
    expect(await jobs(), isEmpty);
  });

  test('a 500 leaves the row pending and schedules another attempt',
      () async {
    goOnline();
    when(() => api.createCustomer(any())).thenAnswer(
      (_) async => const Err(
        AppException('gateway timeout', statusCode: 504),
      ),
    );

    await repository.createCustomer(const CustomerModel(id: 0, name: 'Dara'));

    expect((await rows()).single.syncStatus, SyncStatus.pending);
    final job = (await jobs()).single;
    expect(job.attemptCount, 1);
    expect(job.lastError, contains('gateway timeout'));
  });

  test('a 400 stops the job and marks the row failed', () async {
    goOnline();
    when(() => api.createCustomer(any())).thenAnswer(
      (_) async => const Err(
        AppException('name is required', statusCode: 400),
      ),
    );

    await repository.createCustomer(const CustomerModel(id: 0, name: ''));

    expect((await rows()).single.syncStatus, SyncStatus.failed);
    expect((await jobs()).single.lastError, contains('name is required'));
  });
}
