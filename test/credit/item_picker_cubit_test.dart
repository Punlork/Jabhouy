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

PriceOption _option(
  String id,
  String unit,
  int? price, {
  Currency currency = Currency.khr,
  int? packQty,
}) => PriceOption(
  id: id,
  unit: unit,
  currency: currency,
  price: price,
  packQty: packQty,
);

void main() {
  late AppDatabase db;
  late ItemRepository items;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    final connectivity = _Connectivity();
    when(() => connectivity.isOnline).thenAnswer((_) async => false);
    items = ItemRepository(
      ItemDao(db),
      _Scope(),
      SyncEngine(database: db, transport: AdapterSyncTransport([])),
      connectivity,
    );
    await items.saveCategory(const ItemCategory(id: 'drinks', name: 'ភេសជ្ជៈ'));
    await items.saveItem(
      Item(
        id: 'coke',
        name: 'Coca-Cola',
        categoryId: 'drinks',
        prices: [
          _option('p1', 'ដប', 3000),
          _option('p2', 'កេះ', 750, currency: Currency.usd, packQty: 24),
        ],
      ),
    );
    await items.saveItem(
      Item(
        id: 'rice',
        name: 'អង្ករផ្កាម្លិះ',
        prices: [_option('p3', 'គីឡូ', 3800), _option('p4', 'បេ', null)],
      ),
    );
  });

  tearDown(() => db.close());

  ItemPickerCubit cubit({List<CreditLine> initial = const []}) {
    final c = ItemPickerCubit(items, initial: initial)..start();
    addTearDown(c.close);
    return c;
  }

  Future<ItemPickerState> settled(ItemPickerCubit c) async {
    for (var i = 0; i < 4; i++) {
      await Future<void>.delayed(Duration.zero);
    }
    return c.state;
  }

  test('a chosen option becomes a line with its snapshot', () async {
    final c = cubit();
    await settled(c);

    c
      ..setQty('p1', 2)
      ..setQty('p2', 1);

    final lines = c.state.lines;
    expect(lines.map((l) => (l.name, l.unit, l.qty, l.unitPrice, l.currency)), [
      ('Coca-Cola', 'ដប', 2, 3000, Currency.khr),
      ('Coca-Cola', 'កេះ (24)', 1, 750, Currency.usd),
    ]);
    expect(lines.first.priceId, 'p1');
    c.setQty('p1', 0);
    expect(c.state.lines.map((l) => l.priceId), ['p2']);
  });

  test('an option with no price cannot become a line', () async {
    final c = cubit();
    await settled(c);

    c.setQty('p4', 3);

    expect(c.state.lines, isEmpty);
  });

  test('search and category narrow the items, not the choice', () async {
    final c = cubit();
    await settled(c);
    c
      ..setQty('p3', 5)
      ..search('coca');
    expect(c.state.items.map((i) => i.id), ['coke']);
    expect(c.state.lines.map((l) => l.priceId), ['p3'], reason: 'kept');

    c
      ..search('')
      ..selectCategory('drinks');
    expect(c.state.items.map((i) => i.id), ['coke']);
    c.selectCategory(null);
    expect(c.state.items, hasLength(2));
  });

  test('lines already on the Credit keep their snapshot and id', () async {
    const old = CreditLine(
      id: 'line-1',
      priceId: 'p1',
      name: 'Coke (old name)',
      unit: 'ដប',
      qty: 2,
      currency: Currency.khr,
      unitPrice: 2500, // the price then; now 3,000
    );
    const gone = CreditLine(
      id: 'line-2',
      name: 'ទំនិញលុបហើយ',
      unit: 'ដប',
      qty: 1,
      currency: Currency.khr,
      unitPrice: 100,
      priceId: 'deleted-option',
    );
    final c = cubit(initial: [old, gone]);
    await settled(c);

    expect(c.state.quantities['p1'], 2);
    c.setQty('p1', 4);

    final lines = c.state.lines;
    expect(lines.first.id, 'line-1');
    expect(lines.first.unitPrice, 2500, reason: 'not repriced');
    expect(lines.first.name, 'Coke (old name)');
    expect(lines.first.qty, 4);
    expect(lines.last.id, 'line-2', reason: 'its option is gone: untouched');

    c.setQty('p1', 0);
    expect(c.state.lines.map((l) => l.id), ['line-2'], reason: 'removed');
  });
}
