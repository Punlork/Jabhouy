import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jabhouy/app/widget/sync_indicator.dart';
import 'package:jabhouy_core/jabhouy_core.dart';
import 'package:jabhouy_l10n/jabhouy_l10n.dart';
import 'package:jabhouy_net/jabhouy_net.dart';
import 'package:jabhouy_sync/jabhouy_sync.dart';
import 'package:mocktail/mocktail.dart';

class MockSyncEngine extends Mock implements SyncEngine {}

class MockConnectivityService extends Mock implements ConnectivityService {}

void main() {
  late MockSyncEngine engine;
  late MockConnectivityService connectivity;
  late StreamController<SyncActivity> activity;
  late StreamController<bool> connection;

  setUp(() {
    engine = MockSyncEngine();
    connectivity = MockConnectivityService();
    activity = StreamController<SyncActivity>.broadcast();
    connection = StreamController<bool>.broadcast();
    when(() => engine.activity).thenAnswer((_) => activity.stream);
    when(() => connectivity.connectivityStream)
        .thenAnswer((_) => connection.stream);
    when(() => connectivity.isOnline).thenAnswer((_) async => true);
  });

  tearDown(() async {
    await activity.close();
    await connection.close();
  });

  Future<void> pumpIndicator(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Center(
            child: SyncIndicator(engine: engine, connectivity: connectivity),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  Future<void> emit(WidgetTester tester, SyncActivity next) async {
    activity.add(next);
    await tester.pump();
  }

  testWidgets('a quick save never flashes "Syncing…"', (tester) async {
    await pumpIndicator(tester);

    await emit(tester, const SyncActivity(pushing: true, waiting: 1));
    await tester.pump(const Duration(milliseconds: 500));
    await emit(tester, const SyncActivity());
    await tester.pump(const Duration(seconds: 2));

    expect(find.text('Syncing…'), findsNothing);
    expect(find.text('Synced'), findsNothing);
  });

  testWidgets('a slow sync shows "Syncing…", then "Synced", then nothing',
      (tester) async {
    await pumpIndicator(tester);

    await emit(tester, const SyncActivity(pushing: true, waiting: 3));
    await tester.pump(const Duration(milliseconds: 1100));
    expect(find.text('Syncing…'), findsOneWidget);

    await emit(tester, const SyncActivity());
    await tester.pumpAndSettle(const Duration(milliseconds: 300));
    expect(find.text('Synced'), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.text('Synced'), findsNothing);
  });

  testWidgets('offline with changes queued says how many wait',
      (tester) async {
    await pumpIndicator(tester);

    connection.add(false);
    await emit(tester, const SyncActivity(waiting: 3));
    await tester.pumpAndSettle();

    expect(find.text('3 changes waiting'), findsOneWidget);
  });

  testWidgets('online with changes queued but nothing wrong stays hidden',
      (tester) async {
    await pumpIndicator(tester);

    await emit(tester, const SyncActivity(waiting: 3));
    await tester.pumpAndSettle();

    expect(find.byType(Text), findsNothing);
  });

  testWidgets("failures stay up, and a tap shows the server's reasons",
      (tester) async {
    when(() => engine.failedJobs()).thenAnswer(
      (_) async => [
        OutboxEntry(
          id: 1,
          entityType: SyncEntityType.loaner,
          localId: '37',
          operation: SyncOperation.update,
          idempotencyKey: 'loaner:37:update',
          attemptCount: 1,
          nextAttemptAt: DateTime(9999),
          lastError: 'customerId: Invalid input: expected number',
          createdAt: DateTime(2026, 9, 28),
        ),
      ],
    );
    await pumpIndicator(tester);

    await emit(tester, const SyncActivity(waiting: 1, failing: 1));
    await tester.pumpAndSettle();
    expect(find.text('1 change failed'), findsOneWidget);

    await tester.tap(find.text('1 change failed'));
    await tester.pumpAndSettle();

    expect(find.text('Loaner #37'), findsOneWidget);
    expect(
      find.text('customerId: Invalid input: expected number'),
      findsOneWidget,
    );
  });
}
