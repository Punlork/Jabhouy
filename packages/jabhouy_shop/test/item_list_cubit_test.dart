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
  _Scope({this.role = MemberRole.owner, this.shopId = 's1'});

  @override
  final String? shopId;
  @override
  final MemberRole role;
  @override
  bool get syncs => false;
  @override
  String get userId => 'u1';
}

PriceOption _option(String unit, int? price) =>
    PriceOption(id: newId(), unit: unit, currency: Currency.khr, price: price);

void main() {
  late AppDatabase db;
  late ItemRepository repo;
  final scope = _Scope();

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    final connectivity = _MockConnectivity();
    when(() => connectivity.isOnline).thenAnswer((_) async => false);
    repo = ItemRepository(
      ItemDao(db),
      scope,
      SyncEngine(database: db, transport: AdapterSyncTransport([])),
      connectivity,
    );
    await repo.saveCategory(const ItemCategory(id: 'rice', name: 'អង្ករ'));
    await repo.saveItem(
      Item(id: 'coke', name: 'Coca-Cola', prices: [_option('ដប', 3000)]),
    );
    await repo.saveItem(
      Item(
        id: 'rice',
        name: 'អង្ករផ្កាម្លិះ',
        categoryId: 'rice',
        prices: [_option('គីឡូ', 3800), _option('បេ', null)],
      ),
    );
  });

  tearDown(() => db.close());

  Future<ItemListState> settled(ItemListCubit cubit) async {
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    return cubit.state;
  }

  ItemListCubit cubit({ShopScope? withScope, bool grid = false}) {
    final c = ItemListCubit(repo, withScope ?? scope, grid: grid);
    addTearDown(c.close);
    return c;
  }

  test('nothing is read before start, then every item and the counts',
      () async {
    final list = cubit();
    expect(list.state.loading, isTrue);

    list.start();
    final state = await settled(list);
    expect(state.loading, isFalse);
    expect(state.items.map((i) => i.id), ['coke', 'rice']);
    expect(state.missingCount, 1);
    expect(state.categories.single.name, 'អង្ករ');
  });

  test('a category, the missing-price chip and search each narrow it',
      () async {
    final list = cubit()..start();
    await settled(list);

    list.filter(categoryId: 'rice');
    expect((await settled(list)).items.map((i) => i.id), ['rice']);

    list.filter(missingOnly: true);
    expect((await settled(list)).items.map((i) => i.id), ['rice']);

    list
      ..filter()
      ..search('coca');
    expect((await settled(list)).items.map((i) => i.id), ['coke']);
  });

  test('a viewer never gets the missing-price chip', () async {
    final list = cubit(withScope: _Scope(role: MemberRole.viewer))..start();
    expect((await settled(list)).canEdit, isFalse);
    expect(cubit().state.canEdit, isTrue);
  });

  test('without a Shop yet, start reads nothing and does not throw',
      () async {
    final list = cubit(withScope: _Scope(shopId: null))..start();
    expect((await settled(list)).loading, isTrue);
  });

  test('stop forgets the Shop, so the next sign-in starts afresh', () async {
    final list = cubit(grid: true)..start();
    await settled(list);

    await list.stop();
    expect(list.state.items, isEmpty);
    expect(list.state.grid, isTrue, reason: "the layout is the phone's");
    list.start();
    expect((await settled(list)).items, hasLength(2));
  });

  test('the grid choice is reported so the app can remember it', () async {
    final saved = <bool>[];
    final list = ItemListCubit(repo, scope, onGridChanged: saved.add);
    addTearDown(list.close);

    list.toggleGrid();
    expect(list.state.grid, isTrue);
    expect(saved, [true]);
  });
}
