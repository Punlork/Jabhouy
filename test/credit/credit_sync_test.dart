// Two phones and one in-memory server: what A records, B pulls.
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jabhouy/credit/data/credit_dao.dart';
import 'package:jabhouy/credit/data/credit_repository.dart';
import 'package:jabhouy/credit/data/credit_sync.dart';
import 'package:jabhouy/credit/models/credit.dart';
import 'package:jabhouy_core/jabhouy_core.dart';
import 'package:jabhouy_net/jabhouy_net.dart';
import 'package:jabhouy_sync/jabhouy_sync.dart';
import 'package:mocktail/mocktail.dart';

class _Connectivity extends Mock implements ConnectivityService {}

class _Scope implements ShopScope {
  _Scope(this.userId);

  @override
  final String userId;
  @override
  String get shopId => 's1';
  @override
  MemberRole get role => MemberRole.owner;
  @override
  bool get syncs => true;
}

class _Phone {
  _Phone(String userId, ShopSyncApi api, {bool online = true}) {
    final scope = _Scope(userId);
    final dao = CreditDao(db);
    final connectivity = _Connectivity();
    when(() => connectivity.isOnline).thenAnswer((_) async => online);
    engine = SyncEngine(
      database: db,
      transport: AdapterSyncTransport([
        CreditCustomerSyncAdapter(dao, api, () => scope.shopId),
        CreditSyncAdapter(dao, api, () => scope.shopId),
      ]),
      changesSource: api,
      changeAppliers: [
        CreditCustomerChangeApplier(dao),
        CreditChangeApplier(dao),
      ],
    );
    repo = CreditRepository(dao, scope, engine, connectivity);
  }

  final db = AppDatabase(NativeDatabase.memory());
  late final SyncEngine engine;
  late final CreditRepository repo;

  Future<List<Credit>> credits() =>
      repo.watchCredits(filter: CreditFilter.all).first;
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late InMemoryShopSyncApi api;
  late _Phone a;
  late _Phone b;

  final taken = DateTime.utc(2026, 10, 20, 4, 5);
  Credit credit(String id, {List<CreditLine> lines = const [], int? amount}) =>
      Credit(
        id: id,
        customerId: 'dara',
        currency: Currency.khr,
        khrPerUsd: 4000,
        takenAt: taken,
        dueDate: '2026-11-01',
        note: 'ទិញជំពាក់',
        amount: amount,
        lines: lines,
      );

  setUp(() async {
    api = InMemoryShopSyncApi();
    a = _Phone('ua', api);
    b = _Phone('ub', api);
    await a.repo.saveCustomer(const CreditCustomer(id: 'dara', name: 'ដារ៉ា'));
  });

  tearDown(() async {
    await a.db.close();
    await b.db.close();
  });

  test('a Credit with its lines and its Customer reach the other phone',
      () async {
    await a.repo.saveCredit(
      credit(
        'c1',
        lines: const [
          CreditLine(
            id: 'l1',
            name: 'ទឹក',
            unit: 'ដប',
            qty: 2,
            currency: Currency.khr,
            unitPrice: 3000,
          ),
        ],
      ),
    );
    await a.engine.drain();

    await b.engine.pullShop('s1');

    final read = (await b.repo.credit('c1'))!;
    expect(read.customerName, 'ដារ៉ា');
    expect(read.amount, 6000);
    expect(read.takenAt, taken);
    expect(read.dueDate, '2026-11-01');
    expect(read.khrPerUsd, 4000);
    expect(read.lines.single.qty, 2);
    expect((await b.repo.watchCustomers().first).single.owed, isNotNull);
  });

  test('marking paid and deleting travel too', () async {
    await a.repo.saveCredit(credit('c1', amount: 5000));
    await a.repo.saveCredit(credit('c2', amount: 7000));
    await a.engine.drain();
    await b.engine.pullShop('s1');

    await a.repo.markPaid('c1');
    await a.repo.deleteCredit('c2');
    await a.engine.drain();
    await b.engine.pullShop('s1');

    expect((await b.repo.credit('c1'))!.isPaid, isTrue);
    expect(await b.repo.credit('c1').then((c) => c!.paidAt), isNotNull);
    expect(await b.repo.credit('c2'), isNull);
  });

  test('offline records wait, then the Customer goes before its Credit',
      () async {
    final offline = _Phone('uc', api, online: false);
    addTearDown(offline.db.close);
    await offline.repo.saveCustomer(
      const CreditCustomer(id: 'sok', name: 'សុខា'),
    );
    await offline.repo.saveCredit(
      Credit(
        id: 'c9',
        customerId: 'sok',
        currency: Currency.khr,
        khrPerUsd: 4000,
        takenAt: taken,
        amount: 100,
      ),
    );
    expect(api.writes.where((w) => w.contains('sok') || w.contains('c9')), isEmpty);

    await offline.engine.drain();

    expect(api.writes.indexOf('put creditCustomer sok'),
        lessThan(api.writes.indexOf('put credit c9')));
    await b.engine.pullShop('s1');
    expect((await b.repo.credit('c9'))!.customerName, 'សុខា');
  });
}
