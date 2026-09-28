// Runs under `dart test`. A Flutter import anywhere in this package stops
// the suite loading, which is what keeps the engine platform-free.
import 'dart:async';

import 'package:drift/native.dart';
import 'package:jabhouy_core/jabhouy_core.dart';
import 'package:jabhouy_sync/jabhouy_sync.dart';
import 'package:test/test.dart';

/// A transport whose answers the test dictates, one per push.
class _ScriptedTransport implements SyncTransport {
  _ScriptedTransport(this.outcomes);

  final List<SyncPushOutcome> outcomes;
  final pushed = <OutboxEntry>[];

  @override
  Future<SyncPushOutcome> push(OutboxEntry entry) async {
    pushed.add(entry);
    return outcomes.isEmpty
        ? const SyncPushSucceeded()
        : outcomes.removeAt(0);
  }
}

/// A transport that holds each push open until the test lets it go.
class _HeldTransport implements SyncTransport {
  final pushed = <String>[];
  final _gates = <Completer<SyncPushOutcome>>[];

  @override
  Future<SyncPushOutcome> push(OutboxEntry entry) {
    pushed.add(entry.localId);
    final gate = Completer<SyncPushOutcome>();
    _gates.add(gate);
    return gate.future;
  }

  void releaseAll() {
    for (final gate in _gates) {
      if (!gate.isCompleted) gate.complete(const SyncPushSucceeded());
    }
  }
}

void main() {
  late AppDatabase db;
  late DateTime now;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    // Local, not UTC: drift stores unix seconds and reads back local.
    now = DateTime(2026, 9, 18, 12);
  });

  tearDown(() async {
    await db.close();
  });

  SyncEngine engineWith(
    _ScriptedTransport transport, {
    BackoffPolicy backoff = const BackoffPolicy(),
  }) =>
      SyncEngine(
        database: db,
        transport: transport,
        backoff: backoff,
        clock: () => now,
      );

  Future<void> enqueueItem(
    SyncEngine engine,
    String localId, {
    SyncEntityType type = SyncEntityType.shopItem,
    String? dependsOn,
  }) =>
      engine.enqueue(
        entityType: type,
        localId: localId,
        operation: SyncOperation.create,
        idempotencyKey: 'fp-$localId',
        dependsOnLocalId: dependsOn,
      );

  test('a queued write leaves the outbox once the server accepts it',
      () async {
    final transport = _ScriptedTransport([const SyncPushSucceeded()]);
    final engine = engineWith(transport);

    await enqueueItem(engine, 'item-1');
    expect(await db.select(db.outboxEntries).get(), hasLength(1));

    expect(await engine.drain(), 1);
    expect(await db.select(db.outboxEntries).get(), isEmpty);
  });

  test('a transient failure retries with backoff and succeeds on attempt 3',
      () async {
    final transport = _ScriptedTransport([
      const SyncPushRetryable('500'),
      const SyncPushRetryable('500'),
      const SyncPushSucceeded(),
    ]);
    const backoff = BackoffPolicy(base: Duration(seconds: 10));
    final engine = engineWith(transport, backoff: backoff);

    await enqueueItem(engine, 'item-1');

    expect(await engine.drain(), 0);
    var entry = await db.select(db.outboxEntries).getSingle();
    expect(entry.attemptCount, 1);
    expect(entry.lastError, '500');
    expect(entry.nextAttemptAt, now.add(const Duration(seconds: 20)));

    // Still in the future: the drain loop must not pick it up yet.
    expect(await engine.drain(), 0);
    expect(transport.pushed, hasLength(1));

    now = now.add(const Duration(minutes: 1));
    expect(await engine.drain(), 0);
    entry = await db.select(db.outboxEntries).getSingle();
    expect(entry.attemptCount, 2);

    now = now.add(const Duration(minutes: 10));
    expect(await engine.drain(), 1);
    expect(await db.select(db.outboxEntries).get(), isEmpty);
    expect(transport.pushed, hasLength(3));
  });

  test('an item waits for the offline category it references', () async {
    final transport = _ScriptedTransport([]);
    final engine = engineWith(transport);

    await enqueueItem(engine, 'cat-1', type: SyncEntityType.category);
    await enqueueItem(engine, 'item-1', dependsOn: 'cat-1');

    // Only the category is eligible while its job is still queued.
    final due = await engine.dueEntries();
    expect(due.map((e) => e.localId), ['cat-1']);

    await engine.drain();
    expect(transport.pushed.map((e) => e.localId), ['cat-1', 'item-1']);
  });

  test('a rejected push keeps the job and its reason instead of dropping it',
      () async {
    final transport = _ScriptedTransport([const SyncPushRejected('400 bad')]);
    final engine = engineWith(transport);

    await enqueueItem(engine, 'item-1');
    expect(await engine.drain(), 0);

    final entry = await db.select(db.outboxEntries).getSingle();
    expect(entry.lastError, '400 bad');
    // The old code marked this synced and forgot it.
    expect(await db.select(db.outboxEntries).get(), hasLength(1));
  });

  test('a delete that fails remotely stays queued', () async {
    final transport =
        _ScriptedTransport([const SyncPushRetryable('timeout')]);
    final engine = engineWith(transport);

    await engine.enqueue(
      entityType: SyncEntityType.shopItem,
      localId: 'item-1',
      operation: SyncOperation.delete,
      idempotencyKey: 'fp-delete-1',
    );

    expect(await engine.drain(), 0);
    final entry = await db.select(db.outboxEntries).getSingle();
    expect(entry.operation, SyncOperation.delete);
    expect(entry.lastError, 'timeout');
  });

  test('a second edit before the first is sent is still one push', () async {
    final transport = _ScriptedTransport([]);
    final engine = engineWith(transport);

    await enqueueItem(engine, 'item-1');
    await engine.enqueue(
      entityType: SyncEntityType.shopItem,
      localId: 'item-1',
      operation: SyncOperation.update,
      idempotencyKey: 'fp-item-1-v2',
    );

    expect(await db.select(db.outboxEntries).get(), hasLength(1));
    await engine.drain();
    expect(transport.pushed, hasLength(1));
    expect(transport.pushed.single.operation, SyncOperation.update);
  });

  test('concurrent drains of one idempotency key share a single push', () async {
    final transport = _ScriptedTransport([]);
    final engine = engineWith(transport);
    await enqueueItem(engine, 'item-1');

    await Future.wait([engine.drain(), engine.drain()]);

    expect(transport.pushed, hasLength(1));
  });

  test('backoff doubles and then stops at its ceiling', () {
    const policy = BackoffPolicy(
      base: Duration(seconds: 10),
      max: Duration(minutes: 1),
    );

    expect(policy.delayFor(0), const Duration(seconds: 10));
    expect(policy.delayFor(1), const Duration(seconds: 20));
    expect(policy.delayFor(2), const Duration(seconds: 40));
    expect(policy.delayFor(3), const Duration(minutes: 1));
    expect(policy.delayFor(99), const Duration(minutes: 1));
  });

  group('one drain at a time', () {
    test('a second drain joins the first instead of pushing twice',
        () async {
      final transport = _HeldTransport();
      final engine = SyncEngine(
        database: db,
        transport: transport,
        clock: () => now,
      );
      await enqueueItem(engine, 'item-1');

      final first = engine.drain();
      await pumpEventQueue();
      final second = engine.drain();
      transport.releaseAll();
      await Future.wait([first, second]);

      expect(transport.pushed, ['item-1']);
    });

    test('a job queued mid-drain is pushed by that drain', () async {
      final transport = _HeldTransport();
      final engine = SyncEngine(
        database: db,
        transport: transport,
        clock: () => now,
      );
      await enqueueItem(engine, 'item-1');
      final drained = engine.drain();
      await pumpEventQueue();

      // A save while the first push is still on the wire.
      await enqueueItem(engine, 'item-2');
      engine.requestSync();
      transport.releaseAll();
      await pumpEventQueue();
      transport.releaseAll();
      await drained;

      expect(transport.pushed, ['item-1', 'item-2']);
      expect(await db.select(db.outboxEntries).get(), isEmpty);
    });
  });

  group('a rejected job', () {
    test('is not sent again on the next drain', () async {
      final transport = _ScriptedTransport([
        const SyncPushRejected('400 customerId required'),
      ]);
      final engine = engineWith(transport);
      await enqueueItem(engine, 'loan-37');

      await engine.drain();
      await engine.drain();

      expect(transport.pushed, hasLength(1));
      expect(
        (await db.select(db.outboxEntries).getSingle()).lastError,
        '400 customerId required',
      );
    });

    test('is sent once more after the next launch releases it', () async {
      final transport = _ScriptedTransport([
        const SyncPushRejected('400'),
        const SyncPushSucceeded(),
      ]);
      final engine = engineWith(transport);
      await enqueueItem(engine, 'loan-37');
      await engine.drain();

      await engine.releaseRejected();
      await engine.drain();

      expect(transport.pushed, hasLength(2));
      expect(await db.select(db.outboxEntries).get(), isEmpty);
    });

    test('is due again as soon as its row is edited', () async {
      final transport = _ScriptedTransport([
        const SyncPushRejected('400'),
        const SyncPushSucceeded(),
      ]);
      final engine = engineWith(transport);
      await enqueueItem(engine, 'loan-37');
      await engine.drain();

      await engine.enqueue(
        entityType: SyncEntityType.shopItem,
        localId: 'loan-37',
        operation: SyncOperation.update,
        idempotencyKey: 'fp-loan-37-edit',
      );
      await engine.drain();

      expect(transport.pushed, hasLength(2));
    });
  });

  test('activity counts what is waiting and what is failing', () async {
    final transport = _ScriptedTransport([
      const SyncPushRejected('400'),
      const SyncPushSucceeded(),
    ]);
    final engine = engineWith(transport);
    final seen = <SyncActivity>[];
    final subscription = engine.activity.listen(seen.add);

    await enqueueItem(engine, 'item-1');
    await enqueueItem(engine, 'item-2');
    await engine.drain();
    await pumpEventQueue();
    await subscription.cancel();

    expect(seen.first.waiting, 0, reason: 'starts from the current state');
    expect(seen.any((a) => a.pushing), isTrue);
    final last = seen.last;
    expect(last.pushing, isFalse);
    expect(last.waiting, 1);
    expect(last.failing, 1);
  });
}
