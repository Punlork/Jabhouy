import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:jabhouy/loaner/loaner.dart';
import 'package:jabhouy_core/jabhouy_core.dart';
import 'package:jabhouy_net/jabhouy_net.dart';
import 'package:mocktail/mocktail.dart';

class MockLoanerRepository extends Mock implements LoanerRepository {}

class MockRefreshLoaners extends Mock implements RefreshLoanersUseCase {}

class MockConnectivityService extends Mock implements ConnectivityService {}

void main() {
  late MockLoanerRepository repository;
  late MockRefreshLoaners refresh;
  late LoanerBloc bloc;

  setUp(() {
    repository = MockLoanerRepository();
    refresh = MockRefreshLoaners();
    final connectivity = MockConnectivityService();
    when(() => connectivity.isOnline).thenAnswer((_) async => true);
    when(() => connectivity.connectivityStream)
        .thenAnswer((_) => const Stream.empty());
    when(
      () => repository.watchLoaners(
        searchQuery: any(named: 'searchQuery'),
        customerFilter: any(named: 'customerFilter'),
        fromDate: any(named: 'fromDate'),
        toDate: any(named: 'toDate'),
      ),
    ).thenAnswer((_) => Stream.value([LoanerModel(id: 1, amount: 500)]));
    when(
      () => repository.hasCachedLoaners(
        searchQuery: any(named: 'searchQuery'),
        customerFilter: any(named: 'customerFilter'),
        fromDate: any(named: 'fromDate'),
        toDate: any(named: 'toDate'),
      ),
    ).thenAnswer((_) async => true);
    when(() => repository.pullLatest()).thenAnswer((_) async {});

    bloc = LoanerBloc(
      repository,
      refresh,
      connectivity,
      flags: const FixedFeatureFlags({Feature.backgroundSync}),
    );
  });

  tearDown(() => bloc.close());

  // Past the 300 ms search debounce.
  Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 400));

  test('search, filter and scroll read the phone and call no server',
      () async {
    bloc
      ..add(LoadLoaners())
      ..add(LoadLoaners(searchQuery: 'Dara'))
      ..add(LoadLoaners(fromDate: DateTime(2026, 5), toDate: DateTime(2026, 6)));
    await settle();
    bloc.add(LoadLoaners(page: 2));
    await settle();

    verifyZeroInteractions(refresh);
    verifyNever(() => repository.pullLatest());
    verify(
      () => repository.watchLoaners(
        searchQuery: 'Dara',
        customerFilter: any(named: 'customerFilter'),
        fromDate: any(named: 'fromDate'),
        toDate: any(named: 'toDate'),
      ),
    ).called(1);
  });

  test('pull-to-refresh is the one load that asks the server', () async {
    bloc.add(LoadLoaners(forceRefresh: true));
    await settle();

    verify(() => repository.pullLatest()).called(1);
    verifyZeroInteractions(refresh);
  });

  test('refresh() lasts as long as the pull, so the spinner stays up',
      () async {
    final pull = Completer<void>();
    when(() => repository.pullLatest()).thenAnswer((_) => pull.future);

    var finished = false;
    unawaited(bloc.refresh().then((_) => finished = true));
    await pumpEventQueue();
    expect(finished, isFalse, reason: 'still downloading');

    pull.complete();
    await pumpEventQueue();
    expect(finished, isTrue);
  });
}
