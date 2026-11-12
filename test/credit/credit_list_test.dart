import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jabhouy/credit/credit.dart';
import 'package:jabhouy_core/jabhouy_core.dart';
import 'package:jabhouy_net/jabhouy_net.dart';
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

void main() {
  late AppDatabase db;
  late CreditRepository repo;
  final taken = DateTime.utc(2026, 10, 14, 4);

  Credit credit(
    String id,
    String customer, {
    int? amount,
    String? note,
    CreditStatus status = CreditStatus.unpaid,
  }) => Credit(
    id: id,
    customerId: customer,
    currency: Currency.khr,
    khrPerUsd: 4000,
    takenAt: taken,
    amount: amount,
    note: note,
    status: status,
  );

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    final connectivity = _Connectivity();
    when(() => connectivity.isOnline).thenAnswer((_) async => false);
    repo = CreditRepository(
      CreditDao(db),
      _Scope(),
      SyncEngine(database: db, transport: AdapterSyncTransport([])),
      connectivity,
    );
    await repo.saveCustomer(const CreditCustomer(id: 'bol', name: 'ពូ បុល'));
    await repo.saveCustomer(const CreditCustomer(id: 'mak', name: 'មាក់'));
    await repo.saveCredit(
      credit('c1', 'bol', amount: 23000, note: 'Hanuman 6'),
    );
    await repo.saveCredit(credit('c2', 'mak'));
    await repo.saveCredit(
      credit('c3', 'bol', amount: 9000, status: CreditStatus.paid),
    );
  });

  tearDown(() => db.close());

  CreditListCubit cubit() {
    final c = CreditListCubit(repo)..start();
    addTearDown(c.close);
    return c;
  }

  Future<CreditListState> settled(CreditListCubit c) async {
    for (var i = 0; i < 4; i++) {
      await Future<void>.delayed(Duration.zero);
    }
    return c.state;
  }

  test('starts on មិនទាន់សង with a summary over the unpaid ones', () async {
    final state = await settled(cubit());

    expect(state.loading, isFalse);
    expect(state.credits.map((c) => c.id), unorderedEquals(['c1', 'c2']));
    expect(state.summary!.total, const Money(23000, Currency.khr));
    expect(state.summary!.people, 2);
    expect(state.summary!.peopleWithoutAmount, 1);
  });

  test('the chips and the search narrow the rows, not the summary', () async {
    final c = cubit();
    await settled(c);

    c.filter(CreditFilter.paid);
    expect(c.state.credits.map((x) => x.id), ['c3']);
    expect(c.state.summary!.total, const Money(23000, Currency.khr));

    c.filter(CreditFilter.all);
    expect(c.state.credits, hasLength(3));

    c.search('មាក់');
    expect(c.state.credits.map((x) => x.id), ['c2']);
    expect(c.state.summary!.people, 2);
  });

  test(
    'marking paid moves it out of the unpaid list and the summary',
    () async {
      final c = cubit();
      await settled(c);

      await repo.markPaid('c1');
      final state = await settled(c);

      expect(state.credits.map((x) => x.id), ['c2']);
      expect(state.summary!.total, const Money(0, Currency.khr));
    },
  );

  test('stop forgets the Shop; start reads again', () async {
    final c = cubit();
    await settled(c);
    await c.stop();
    expect(c.state.credits, isEmpty);
    c.start();
    expect((await settled(c)).credits, hasLength(2));
  });

  test('A–Z sorts by customer; tapping it again reverses', () async {
    final saved = <(CreditSort, bool)>[];
    final c = CreditListCubit(
      repo,
      onSortChanged: (sort, {required reversed}) => saved.add((sort, reversed)),
    )..start();
    addTearDown(c.close);
    await settled(c);

    c.setSort(CreditSort.name);
    expect(c.state.credits.map((x) => x.id), ['c1', 'c2']);
    c.setSort(CreditSort.name);
    expect(c.state.credits.map((x) => x.id), ['c2', 'c1']);
    expect(saved, [(CreditSort.name, false), (CreditSort.name, true)]);
  });
}
