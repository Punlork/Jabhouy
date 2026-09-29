import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:jabhouy_core/jabhouy_core.dart';
import 'package:jabhouy_net/jabhouy_net.dart';
import 'package:jabhouy_shop/jabhouy_shop.dart';
import 'package:jabhouy_ui/jabhouy_ui.dart';
import 'package:mocktail/mocktail.dart';

class MockShopRepository extends Mock implements ShopRepository {}

class MockUploadBloc extends Mock implements UploadBloc {}

class MockConnectivityService extends Mock implements ConnectivityService {}

void main() {
  late MockShopRepository repository;
  late MockConnectivityService connectivity;
  late StreamController<List<ShopItemModel>> table;
  late ShopBloc bloc;

  const coke = ShopItemModel(id: 1, name: 'Coca Cola');

  setUp(() {
    repository = MockShopRepository();
    connectivity = MockConnectivityService();
    table = StreamController<List<ShopItemModel>>.broadcast();
    when(() => connectivity.isOnline).thenAnswer((_) async => true);
    when(() => connectivity.connectivityStream)
        .thenAnswer((_) => const Stream.empty());
    when(
      () => repository.watchItems(
        searchQuery: any(named: 'searchQuery'),
        categoryFilter: any(named: 'categoryFilter'),
      ),
    ).thenAnswer((_) async* {
      yield const [];
      yield* table.stream;
    });
    when(
      () => repository.hasCachedItems(
        searchQuery: any(named: 'searchQuery'),
        categoryFilter: any(named: 'categoryFilter'),
      ),
    ).thenAnswer((_) async => false);
    when(() => repository.pullLatest()).thenAnswer((_) async {});

    bloc = ShopBloc(
      repository,
      MockUploadBloc(),
      connectivity,
      flags: const FixedFeatureFlags({Feature.backgroundSync}),
    );
  });

  tearDown(() async {
    await bloc.close();
    await table.close();
  });

  test('an empty phone shows loading until the first download lands',
      () async {
    final pull = Completer<void>();
    when(() => repository.pullLatest()).thenAnswer((_) => pull.future);
    final states = <ShopState>[];
    final sub = bloc.stream.listen(states.add);

    bloc.add(ShopGetItemsEvent());
    await pumpEventQueue();
    expect(states, [isA<ShopLoading>()], reason: 'no empty view flash');

    table.add(const [coke]);
    pull.complete();
    await pumpEventQueue();
    expect(states.last, isA<ShopLoaded>());
    expect((states.last as ShopLoaded).items, [coke]);
    await sub.cancel();
  });

  test('a download that brings nothing ends on the empty list', () async {
    bloc.add(ShopGetItemsEvent());
    await pumpEventQueue();

    expect(bloc.state, isA<ShopLoaded>());
    expect((bloc.state as ShopLoaded).items, isEmpty);
    verify(() => repository.pullLatest()).called(1);
  });

  test('a failed download still ends on the list', () async {
    when(() => repository.pullLatest()).thenThrow(Exception('timeout'));
    bloc.add(ShopGetItemsEvent());
    await pumpEventQueue();

    expect(bloc.state, isA<ShopLoaded>());
  });

  test('offline, the first load does not wait on a download', () async {
    when(() => connectivity.isOnline).thenAnswer((_) async => false);
    bloc.add(ShopGetItemsEvent());
    await pumpEventQueue();

    expect(bloc.state, isA<ShopLoaded>());
    verifyNever(() => repository.pullLatest());
  });

  test('cached items show at once with no download', () async {
    when(
      () => repository.hasCachedItems(
        searchQuery: any(named: 'searchQuery'),
        categoryFilter: any(named: 'categoryFilter'),
      ),
    ).thenAnswer((_) async => true);
    bloc.add(ShopGetItemsEvent());
    await pumpEventQueue();
    table.add(const [coke]);
    await pumpEventQueue();

    expect((bloc.state as ShopLoaded).items, [coke]);
    verifyNever(() => repository.pullLatest());
  });
}
