// Runs against a real in-memory database, like item_repository_test.
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jabhouy_core/jabhouy_core.dart';
import 'package:jabhouy_net/jabhouy_net.dart';
import 'package:jabhouy_shop/jabhouy_shop.dart';
import 'package:jabhouy_sync/jabhouy_sync.dart';
import 'package:mocktail/mocktail.dart';

class _MockConnectivity extends Mock implements ConnectivityService {}

class _Scope implements ShopScope {
  @override
  String get shopId => 's1';
  @override
  bool get syncs => false;
  @override
  MemberRole get role => MemberRole.owner;
  @override
  String get userId => 'u1';
}

ItemDraft _draft(String name, List<PriceRowDraft> rows, {String id = 'i1'}) =>
    ItemDraft(id: id, name: name, rows: rows);

PriceRowDraft _row(String unit, String price, {String packQty = ''}) =>
    PriceRowDraft(
      id: newId(),
      currency: Currency.khr,
      unit: unit,
      price: price,
      packQty: packQty,
    );

void main() {
  late AppDatabase db;
  late ItemRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    final connectivity = _MockConnectivity();
    when(() => connectivity.isOnline).thenAnswer((_) async => false);
    repo = ItemRepository(
      ItemDao(db),
      _Scope(),
      SyncEngine(database: db, transport: AdapterSyncTransport([])),
      connectivity,
    );
  });

  tearDown(() => db.close());

  test('loads categories, settings and the last used category', () async {
    await repo.saveCategory(const ItemCategory(id: 'rice', name: 'អង្ករ'));
    await repo.saveItem(
      const Item(id: 'old', name: 'អង្ករ', categoryId: 'rice', prices: []),
    );
    final cubit = ItemFormCubit(repo);
    addTearDown(cubit.close);

    await cubit.load();

    expect(cubit.state.status, ItemFormStatus.ready);
    expect(cubit.state.categories.single.name, 'អង្ករ');
    expect(cubit.state.categoryId, 'rice');
    expect(cubit.state.settings.useCost, isTrue);
  });

  test('ដប 3,000 ៛ + កេះ ×24 60,000 ៛ saves one item with two prices',
      () async {
    final cubit = ItemFormCubit(repo);
    addTearDown(cubit.close);
    await cubit.load();

    await cubit.save(
      _draft('Coca-Cola', [
        _row('ដប', '3,000'),
        _row('កេះ', '60,000', packQty: '24'),
        _row('', ''),
      ]),
    );

    expect(cubit.state.status, ItemFormStatus.saved);
    final item = (await repo.watchItems().first).single;
    expect(item.prices.map((p) => (p.unit, p.packQty, p.price)), [
      ('ដប', null, 3000),
      ('កេះ', 24, 60000),
    ]);
  });

  test('a problem blocks saving and nothing is written', () async {
    final cubit = ItemFormCubit(repo);
    addTearDown(cubit.close);
    await cubit.load();

    await cubit.save(_draft('', [_row('ដប', '3000.5')]));

    expect(cubit.state.status, ItemFormStatus.ready);
    expect(cubit.state.problems.keys, hasLength(2));
    expect(await repo.watchItems().first, isEmpty);
  });

  test('a barcode used by another item blocks saving', () async {
    await repo.saveItem(
      Item(
        id: 'coke',
        name: 'Coca-Cola',
        prices: [
          PriceOption(
            id: newId(),
            unit: 'ដប',
            currency: Currency.khr,
            barcode: '885',
          ),
        ],
      ),
    );
    final cubit = ItemFormCubit(repo);
    addTearDown(cubit.close);
    await cubit.load();

    await cubit.save(
      _draft('Pepsi', [
        const PriceRowDraft(
          id: 'r1',
          unit: 'ដប',
          currency: Currency.khr,
          barcode: '885',
        ),
      ]),
    );

    expect(cubit.state.problems, {
      'r1.barcode': const FormProblem(ProblemKind.barcodeUsed, 'Coca-Cola'),
    });
  });

  test('a duplicate name warns once, then the next save goes through',
      () async {
    await repo.saveItem(
      Item(id: 'coke', name: 'Coca-Cola', prices: [_row('ដប', '1').toOption()]),
    );
    final cubit = ItemFormCubit(repo);
    addTearDown(cubit.close);
    await cubit.load();
    final draft = _draft('coca-cola', [_row('ដប', '3,000')]);

    await cubit.save(draft);
    expect(cubit.state.duplicateOf, 'coke');
    expect(cubit.state.status, ItemFormStatus.ready);

    await cubit.save(draft);
    expect(cubit.state.status, ItemFormStatus.saved);
    expect(await repo.watchItems().first, hasLength(2));
  });

  test('a new category is saved, listed and picked', () async {
    final cubit = ItemFormCubit(repo);
    addTearDown(cubit.close);
    await cubit.load();

    await cubit.createCategory('  នំ  ');

    final saved = await repo.watchCategories().first;
    expect(saved.map((c) => c.name), contains('នំ'));
    final created = saved.firstWhere((c) => c.name == 'នំ');
    expect(cubit.state.categoryId, created.id);
    expect(cubit.state.categories.map((c) => c.id), contains(created.id));
  });

  test('editing keeps the item and its category', () async {
    const existing = Item(
      id: 'coke',
      name: 'Coca-Cola',
      categoryId: 'drinks',
      prices: [],
    );
    final cubit = ItemFormCubit(repo, existing: existing);
    addTearDown(cubit.close);

    await cubit.load();

    expect(cubit.state.categoryId, 'drinks');
  });
}

extension on PriceRowDraft {
  PriceOption toOption() => PriceOption(
    id: id,
    unit: unit,
    currency: currency,
    price: Money.tryParse(price, currency)?.amount,
  );
}
