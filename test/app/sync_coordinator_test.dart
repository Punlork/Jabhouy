import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:jabhouy/app/service/sync_coordinator.dart';
import 'package:jabhouy_net/jabhouy_net.dart';
import 'package:jabhouy_sync/jabhouy_sync.dart';
import 'package:mocktail/mocktail.dart';

class MockSyncEngine extends Mock implements SyncEngine {}

class MockConnectivityService extends Mock implements ConnectivityService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockSyncEngine engine;
  late MockConnectivityService connectivity;
  late StreamController<bool> connection;
  late SyncCoordinator coordinator;

  setUp(() {
    engine = MockSyncEngine();
    connectivity = MockConnectivityService();
    connection = StreamController<bool>.broadcast();
    when(() => connectivity.connectivityStream)
        .thenAnswer((_) => connection.stream);
    when(() => connectivity.isOnline).thenAnswer((_) async => true);
    when(() => engine.pull()).thenAnswer((_) async {});
    when(() => engine.retryNow()).thenAnswer((_) async {});
    coordinator = SyncCoordinator(engine, connectivity);
  });

  tearDown(() async {
    coordinator.stop();
    await connection.close();
  });

  test('pulls once on start, and starting twice does not double it',
      () async {
    coordinator
      ..start()
      ..start();
    await pumpEventQueue();

    verify(() => engine.pull()).called(1);
  });

  test('a reconnect retries backed-off pushes, then pulls', () async {
    coordinator.start();
    await pumpEventQueue();
    clearInteractions(engine);

    connection.add(true);
    await pumpEventQueue();

    verifyInOrder([() => engine.retryNow(), () => engine.pull()]);
  });

  test('offline, nothing is tried', () async {
    when(() => connectivity.isOnline).thenAnswer((_) async => false);

    coordinator.start();
    await pumpEventQueue();

    verifyNever(() => engine.pull());
  });

  test('after sign-out, a reconnect does nothing', () async {
    coordinator.start();
    await pumpEventQueue();
    coordinator.stop();
    clearInteractions(engine);

    connection.add(true);
    await pumpEventQueue();

    verifyZeroInteractions(engine);
  });
}
