import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jabhouy/credit/credit.dart';
import 'package:jabhouy_core/jabhouy_core.dart';
import 'package:jabhouy_net/jabhouy_net.dart';
import 'package:jabhouy_shop/jabhouy_shop.dart';
import 'package:jabhouy_sync/jabhouy_sync.dart';
import 'package:mocktail/mocktail.dart';

class _Connectivity extends Mock implements ConnectivityService {}

class _Scope implements ShopScope {
  @override
  MemberRole get role => MemberRole.owner;
  @override
  String get shopId => 's1';
  @override
  bool get syncs => false;
  @override
  String get userId => 'u1';
}

CreditLine _line(String id, int qty, int price) => CreditLine(
  id: id,
  name: id,
  unit: 'ដប',
  qty: qty,
  currency: Currency.khr,
  unitPrice: price,
);

void main() {
  late AppDatabase db;
  late CreditRepository credits;
  late ItemRepository items;
  final now = DateTime.utc(2026, 10, 20, 4, 5);
  const dara = CreditCustomer(id: 'dara', name: 'ដារ៉ា');

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    final connectivity = _Connectivity();
    when(() => connectivity.isOnline).thenAnswer((_) async => false);
    final scope = _Scope();
    final engine = SyncEngine(
      database: db,
      transport: AdapterSyncTransport([]),
    );
    credits = CreditRepository(CreditDao(db), scope, engine, connectivity);
    items = ItemRepository(ItemDao(db), scope, engine, connectivity);
    await credits.saveCustomer(dara);
  });

  tearDown(() => db.close());

  CreditFormCubit cubit({Credit? existing}) =>
      CreditFormCubit(credits, existing: existing, clock: () => now);

  test(
    'a new Credit takes the shop currency, rate and the current moment',
    () async {
      await items.savePriceSettings(
        const PriceSettings(currency: Currency.usd, khrPerUsd: 4100),
      );
      final form = cubit();
      expect(form.state.status, CreditFormStatus.loading);

      await form.load();

      expect(form.state.status, CreditFormStatus.ready);
      expect(form.state.currency, Currency.usd);
      expect(form.state.khrPerUsd, 4100);
      expect(form.state.takenAt, now);
    },
  );

  test('2 × 3,000 + 5 × 3,800 saves 25,000 ៛ with the trimmed note', () async {
    final form = cubit();
    await form.load();
    form
      ..setCustomer(dara)
      ..setLines([_line('a', 2, 3000), _line('b', 5, 3800)]);
    expect(form.state.total, const Money(25000, Currency.khr));

    await form.save('  Hanuman 6  ');

    expect(form.state.status, CreditFormStatus.saved);
    final saved = (await credits.watchCredits().first).single;
    expect(saved.amount, 25000);
    expect(saved.note, 'Hanuman 6');
    expect(saved.customerName, 'ដារ៉ា');
  });

  test('saving without a customer says so and saves nothing', () async {
    final form = cubit();
    await form.load();
    form.setTyped(100, Currency.khr);

    await form.save('');

    expect(form.state.customerMissing, isTrue);
    expect(form.state.status, CreditFormStatus.ready);
    expect(await credits.watchCredits(filter: CreditFilter.all).first, isEmpty);

    form.setCustomer(dara);
    expect(form.state.customerMissing, isFalse);
  });

  test('lines drop a typed amount; a count of 0 removes a line', () async {
    final form = cubit();
    await form.load();
    form
      ..setCustomer(dara)
      ..setTyped(9999, Currency.khr)
      ..setLines([_line('a', 1, 3000), _line('b', 1, 500)]);
    expect(form.state.amount, isNull);

    form.setQty('b', 0);
    expect(form.state.lines.map((l) => l.id), ['a']);
    form.setQty('a', 3);
    expect(form.state.total, const Money(9000, Currency.khr));

    form
      ..setLines(const [])
      ..setTyped(7000, Currency.khr);
    await form.save('');
    expect((await credits.watchCredits().first).single.amount, 7000);
  });

  test('the currency switch re-converts the lines', () async {
    final form = cubit();
    await form.load();
    form
      ..setLines([_line('a', 1, 40000)])
      ..setCurrency(Currency.usd);

    expect(form.state.total, const Money(1000, Currency.usd), reason: r'$10');
  });

  test('a due date is saved as the local day and can be cleared', () async {
    final form = cubit();
    await form.load();
    form
      ..setCustomer(dara)
      ..setTyped(100, Currency.khr)
      ..setDueDate(DateTime(2026, 11, 2));
    await form.save('');
    expect((await credits.watchCredits().first).single.dueDate, '2026-11-02');

    final saved = (await credits.watchCredits().first).single;
    final edit = cubit(existing: await credits.credit(saved.id));
    expect(edit.state.dueDate, DateTime(2026, 11, 2));
    edit.setDueDate(null);
    await edit.save('');
    expect((await credits.credit(saved.id))!.dueDate, isNull);
  });

  test('editing keeps the id and the rate it was made at', () async {
    await credits.saveCredit(
      Credit(
        id: 'c1',
        customerId: 'dara',
        currency: Currency.usd,
        khrPerUsd: 4000,
        takenAt: now,
        lines: const [
          CreditLine(
            id: 'l1',
            name: 'x',
            unit: 'ដប',
            qty: 1,
            currency: Currency.usd,
            unitPrice: 500,
          ),
        ],
      ),
    );
    await items.savePriceSettings(const PriceSettings(khrPerUsd: 4200));
    final form = cubit(existing: await credits.credit('c1'));
    await form.load();

    expect(form.state.khrPerUsd, 4000, reason: 'not the shop rate');
    form.setStatus(CreditStatus.paid);
    await form.save('note');

    final saved = (await credits.credit('c1'))!;
    expect(saved.khrPerUsd, 4000);
    expect(saved.isPaid, isTrue);
    expect(saved.paidAt, isNotNull);
    expect(saved.note, 'note');
    expect(
      await credits.watchCredits(filter: CreditFilter.all).first,
      hasLength(1),
    );
  });
}
