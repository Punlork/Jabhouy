import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jabhouy/credit/data/credit_dao.dart';
import 'package:jabhouy/credit/data/credit_repository.dart';
import 'package:jabhouy/credit/logic/credit_money.dart';
import 'package:jabhouy/credit/models/credit.dart';
import 'package:jabhouy_core/jabhouy_core.dart';
import 'package:jabhouy_net/jabhouy_net.dart';
import 'package:jabhouy_shop/jabhouy_shop.dart';
import 'package:jabhouy_sync/jabhouy_sync.dart';
import 'package:mocktail/mocktail.dart';

class _Connectivity extends Mock implements ConnectivityService {}

class _Scope implements ShopScope {
  _Scope(this.role);

  @override
  final MemberRole role;
  @override
  String get shopId => 's1';
  @override
  bool get syncs => false;
  @override
  String get userId => 'u1';
}

CreditLine _line(String name, int qty, int price, [Currency c = Currency.khr]) =>
    CreditLine(
      id: newId(),
      name: name,
      unit: 'ដប',
      qty: qty,
      currency: c,
      unitPrice: price,
    );

void main() {
  late AppDatabase db;
  late CreditRepository repo;
  late ItemRepository items;
  var now = DateTime.utc(2026, 10, 20, 4);

  CreditRepository build(MemberRole role) {
    final connectivity = _Connectivity();
    when(() => connectivity.isOnline).thenAnswer((_) async => false);
    final scope = _Scope(role);
    final engine = SyncEngine(database: db, transport: AdapterSyncTransport([]));
    items = ItemRepository(ItemDao(db), scope, engine, connectivity);
    return CreditRepository(
      CreditDao(db),
      scope,
      engine,
      connectivity,
      clock: () => now,
    );
  }

  Credit credit(
    String id, {
    String customer = 'dara',
    List<CreditLine> lines = const [],
    int? amount,
    Currency currency = Currency.khr,
    int rate = 4000,
    CreditStatus status = CreditStatus.unpaid,
  }) => Credit(
    id: id,
    customerId: customer,
    currency: currency,
    khrPerUsd: rate,
    takenAt: now,
    amount: amount,
    status: status,
    lines: lines,
  );

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repo = build(MemberRole.owner);
    await repo.saveCustomer(const CreditCustomer(id: 'dara', name: 'ដារ៉ា'));
    await repo.saveCustomer(const CreditCustomer(id: 'sok', name: 'សុខា'));
  });

  tearDown(() => db.close());

  Future<List<Credit>> list([
    CreditFilter filter = CreditFilter.unpaid,
    String search = '',
  ]) => repo.watchCredits(filter: filter, search: search).first;

  test('2 × 3,000 + 5 × 3,800 saves 25,000 ៛ and reads back with its lines',
      () async {
    final saved = await repo.saveCredit(
      credit('c1', lines: [_line('ទឹក', 2, 3000), _line('អង្ករ', 5, 3800)]),
    );

    expect((saved as Ok<Credit>).value.amount, 25000);
    final read = (await repo.credit('c1'))!;
    expect(read.amount, 25000);
    expect(read.lines.map((l) => l.qty), [2, 5]);
    expect(read.customerName, 'ដារ៉ា');
    expect(amountOf(read), const Money(25000, Currency.khr));
  });

  test('with lines a typed amount is ignored; without, it stands', () async {
    await repo.saveCredit(
      credit('c1', amount: 1, lines: [_line('ទឹក', 1, 3000)]),
    );
    await repo.saveCredit(credit('c2', amount: 7000));
    await repo.saveCredit(credit('c3'));

    expect((await repo.credit('c1'))!.amount, 3000);
    expect((await repo.credit('c2'))!.amount, 7000);
    expect((await repo.credit('c3'))!.amount, isNull);
  });

  test('a shop rate change leaves a saved Credit and the summary alone',
      () async {
    await repo.saveCredit(
      credit('c1', currency: Currency.usd, lines: [_line('a', 1, 500, Currency.usd)]),
    );
    final before = summarize(await list(), Currency.khr);

    await items.savePriceSettings(const PriceSettings(khrPerUsd: 4200));

    expect((await repo.currentRates()).khrPerUsd, 4200, reason: 'new Credits');
    final after = summarize(await list(), Currency.khr);
    expect(after.total, before.total);
    expect(before.total, const Money(20000, Currency.khr), reason: r'$5 at 4,000');
    expect((await repo.credit('c1'))!.khrPerUsd, 4000);
  });

  test('marking paid sets paid_at and moves it between the chips', () async {
    await repo.saveCredit(credit('c1', amount: 5000));
    now = DateTime.utc(2026, 10, 21, 2);

    await repo.markPaid('c1');

    final paid = (await repo.credit('c1'))!;
    expect(paid.status, CreditStatus.paid);
    expect(paid.paidAt, DateTime.utc(2026, 10, 21, 2));
    expect(await list(), isEmpty);
    expect(await list(CreditFilter.paid), hasLength(1));
    expect(await list(CreditFilter.all), hasLength(1));
  });

  test('search narrows by customer name', () async {
    await repo.saveCredit(credit('c1', amount: 1));
    await repo.saveCredit(credit('c2', customer: 'sok', amount: 2));

    expect((await list(CreditFilter.all, 'សុខា')).map((c) => c.id), ['c2']);
  });

  test('saving needs a real customer', () async {
    final result = await repo.saveCredit(credit('c1', customer: 'nobody'));
    expect(result, isA<Err<Credit>>());
    expect(await list(CreditFilter.all), isEmpty);
  });

  test('a Customer with any Credit, even paid, cannot be deleted', () async {
    await repo.saveCredit(credit('c1', amount: 5000, status: CreditStatus.paid));

    expect(await repo.deleteCustomer('dara'), isA<Err<void>>());
    expect(await repo.deleteCustomer('sok'), isA<Ok<void>>());
    final names = (await repo.watchCustomers().first).map((b) => b.customer.name);
    expect(names, ['ដារ៉ា']);
  });

  test('balances sum the unpaid, each at its own rate, in the default currency',
      () async {
    await repo.saveCredit(credit('c1', amount: 10000));
    await repo.saveCredit(
      credit('c2', currency: Currency.usd, amount: 100, rate: 4100),
    );
    await repo.saveCredit(credit('c3'));
    await repo.saveCredit(credit('c4', amount: 9999, status: CreditStatus.paid));

    final dara = (await repo.watchCustomers().first)
        .firstWhere((b) => b.customer.id == 'dara');

    expect(dara.owed, const Money(14100, Currency.khr), reason: r'10,000 + $1');
    expect(dara.unknownCount, 1);
    expect(dara.creditCount, 4);
    final sok = (await repo.watchCustomers(search: 'សុខា').first).single;
    expect(sok.owed, isNull);
  });

  test('a viewer records Credits but cannot delete one', () async {
    final viewer = build(MemberRole.viewer);
    expect(await viewer.saveCredit(credit('c1', amount: 100)), isA<Ok<Credit>>());
    expect(await viewer.markPaid('c1'), isA<Ok<void>>());

    expect(await viewer.deleteCredit('c1'), isA<Err<void>>());
    expect(await viewer.deleteCustomer('sok'), isA<Err<void>>());
    expect(await repo.credit('c1'), isNotNull);

    expect(await repo.deleteCredit('c1'), isA<Ok<void>>());
    expect(await repo.credit('c1'), isNull);
  });
}
