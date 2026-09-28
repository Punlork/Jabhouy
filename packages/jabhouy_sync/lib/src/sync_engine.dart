import 'dart:async';

import 'package:drift/drift.dart';
import 'package:jabhouy_core/jabhouy_core.dart';
import 'package:jabhouy_sync/src/backoff.dart';
import 'package:jabhouy_sync/src/feature_pull_adapter.dart';
import 'package:jabhouy_sync/src/transport.dart';

/// What the engine is doing, for the sync indicator.
///
/// Whether the device is offline is the app's to know, not the engine's;
/// the indicator combines the two.
class SyncActivity {
  const SyncActivity({
    this.pushing = false,
    this.waiting = 0,
    this.failing = 0,
  });

  /// A drain is running.
  final bool pushing;

  /// Jobs still in the outbox, failing ones included.
  final int waiting;

  /// Jobs whose last attempt failed: retrying, or rejected until relaunch.
  final int failing;

  bool _sameAs(SyncActivity other) =>
      other.pushing == pushing &&
      other.waiting == waiting &&
      other.failing == failing;

  @override
  String toString() =>
      'SyncActivity(pushing: $pushing, waiting: $waiting, failing: $failing)';
}

/// When a rejected job is next due: never, until [SyncEngine.releaseRejected].
///
/// The server refused these bytes, so sending them again on every drain
/// only repeats the refusal; a new build may fix what built them.
final _parked = DateTime(9999);

/// Drains the outbox.
///
/// Generalises `firebase_income_sync_service.dart`, the one sync path in the
/// app that does not lose writes, and adds the three things it lacked:
/// backoff, dependency ordering, and a checked delete result.
class SyncEngine {
  SyncEngine({
    required AppDatabase database,
    required SyncTransport transport,
    this.backoff = const BackoffPolicy(),
    SyncDiagnostics diagnostics = const NoopSyncDiagnostics(),
    DateTime Function() clock = DateTime.now,
    int recentKeyLimit = 200,
    List<FeaturePullAdapter> pullAdapters = const [],
    this.pullInterval = const Duration(minutes: 15),
  })  : _db = database,
        _transport = transport,
        _pullAdapters = {
          for (final adapter in pullAdapters) adapter.entityType: adapter,
        },
        _diagnostics = diagnostics,
        _clock = clock,
        _recentLimit = recentKeyLimit;

  final AppDatabase _db;
  final SyncTransport _transport;
  final SyncDiagnostics _diagnostics;
  final DateTime Function() _clock;
  final int _recentLimit;

  final BackoffPolicy backoff;

  final Map<SyncEntityType, FeaturePullAdapter> _pullAdapters;

  /// How long a pull stays fresh. One seller on usually one phone makes
  /// almost every change on this device, so this only bounds how old
  /// another device's edits can look.
  final Duration pullInterval;

  /// Parents first, so a shop item's category and a loan's customer are
  /// already on the phone when the child arrives.
  static const _pullOrder = [
    SyncEntityType.category,
    SyncEntityType.customer,
    SyncEntityType.shopItem,
    SyncEntityType.loaner,
  ];

  /// The end of the queue of drains and pulls. Each waits for the one
  /// before it, so a pull never sees a half-finished push: a create that
  /// landed mid-pull would be missing from the list the pull downloaded,
  /// and the pull's delete step would remove it.
  Future<void> _tail = Future.value();

  Future<T> _exclusively<T>(Future<T> Function() body) {
    final next = _tail.then((_) => body());
    _tail = next.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return next;
  }

  /// Pushes in flight, keyed by idempotency key.
  ///
  /// Two drains racing on the same job join the same future instead of
  /// sending it twice, as `_inFlightNotificationSyncs` does for income.
  final Map<String, Future<SyncPushOutcome>> _inFlight = {};

  /// Keys that recently succeeded, oldest first.
  ///
  /// Bounded, like income's `_rememberSyncedFingerprint` at 200 entries: an
  /// unbounded set would grow for the life of the process.
  final _recentlySynced = <String>[];

  /// The drain in progress, if any. Only one runs at a time.
  Future<int>? _running;

  /// Set when a drain is asked for while one runs; the running one loops
  /// once more instead of a second starting beside it.
  var _again = false;

  final _activity = StreamController<SyncActivity>.broadcast();
  var _lastActivity = const SyncActivity();

  /// The current activity, then every change.
  Stream<SyncActivity> get activity async* {
    yield _lastActivity;
    yield* _activity.stream;
  }

  Future<void> _publish() async {
    final jobs = await _db.select(_db.outboxEntries).get();
    final next = SyncActivity(
      pushing: _running != null,
      waiting: jobs.length,
      failing: jobs.where((job) => job.lastError != null).length,
    );
    if (next._sameAs(_lastActivity)) return;
    _lastActivity = next;
    _activity.add(next);
  }

  /// Queues a write, or folds it into the job already waiting for that row.
  ///
  /// A second edit before the first reaches the server is still one push.
  Future<void> enqueue({
    required SyncEntityType entityType,
    required String localId,
    required SyncOperation operation,
    required String idempotencyKey,
    String? dependsOnLocalId,
  }) async {
    await _db.into(_db.outboxEntries).insert(
          OutboxEntriesCompanion.insert(
            entityType: entityType,
            localId: localId,
            operation: operation,
            idempotencyKey: idempotencyKey,
            dependsOnLocalId: Value(dependsOnLocalId),
            nextAttemptAt: Value(_clock()),
          ),
          // Fold into the job already waiting for this row. The default
          // conflict target is the primary key, which is not the constraint
          // that expresses "one live job per row".
          onConflict: DoUpdate<$OutboxEntriesTable, OutboxEntry>(
            (_) => OutboxEntriesCompanion(
              operation: Value(operation),
              idempotencyKey: Value(idempotencyKey),
              dependsOnLocalId: Value(dependsOnLocalId),
              // A fresh edit supersedes the old bytes, so the previous
              // failure and its schedule no longer apply.
              attemptCount: const Value(0),
              lastError: const Value(null),
              nextAttemptAt: Value(_clock()),
            ),
            target: [
              _db.outboxEntries.entityType,
              _db.outboxEntries.localId,
            ],
          ),
        );
    unawaited(_publish());
    _diagnostics.log(
      'enqueued',
      data: {
        'entityType': entityType.name,
        'localId': localId,
        'operation': operation.name,
      },
    );
  }

  /// Jobs that are due now and whose dependency has already cleared.
  Future<List<OutboxEntry>> dueEntries() async {
    final now = _clock();
    final due = await (_db.select(_db.outboxEntries)
          ..where((t) => t.nextAttemptAt.isSmallerOrEqualValue(now))
          ..orderBy([(t) => OrderingTerm.asc(t.id)]))
        .get();

    // A job whose dependency is still queued must not go first. This is the
    // defect where an item reached the server before its offline category.
    final queuedIds = (await _db.select(_db.outboxEntries).get())
        .map((e) => e.localId)
        .toSet();

    return due
        .where(
          (e) =>
              e.dependsOnLocalId == null ||
              !queuedIds.contains(e.dependsOnLocalId),
        )
        .toList();
  }

  /// Starts a drain without waiting for it: what a save calls.
  void requestSync() => unawaited(drain());

  /// Pushes due jobs until no further progress is possible.
  ///
  /// A call while a drain runs joins it and makes it loop once more, so a
  /// job queued mid-drain is not left behind and no job is pushed by two
  /// drains at once.
  Future<int> drain() {
    final running = _running;
    if (running != null) {
      _again = true;
      return running;
    }
    return _running = _exclusively(_run);
  }

  Future<int> _run() async {
    var total = 0;
    try {
      unawaited(_publish());
      do {
        _again = false;
        total += await _drainOnce();
      } while (_again);
    } finally {
      // Cleared in the same step as the last `_again` check, so a call
      // cannot slip between them and be dropped.
      _running = null;
    }
    await _publish();
    return total;
  }

  /// Repeats because clearing a job makes anything that depended on it
  /// eligible: a category leaving the queue releases its shop items in the
  /// same drain rather than the next one. Each pass that clears nothing
  /// ends the loop, and jobs only ever leave the queue, so it terminates.
  Future<int> _drainOnce() async {
    var total = 0;
    while (true) {
      var cleared = 0;
      for (final entry in await dueEntries()) {
        if (await _push(entry)) cleared++;
      }
      if (cleared == 0) return total;
      total += cleared;
    }
  }

  /// Downloads every list that is stale, or every list at all with
  /// [force], optionally limited to [only]. Drains first, so the server
  /// has this phone's writes before it is asked for the list.
  Future<void> pull({bool force = false, Set<SyncEntityType>? only}) =>
      _exclusively(() => _pull(force: force, only: only));

  Future<void> _pull({required bool force, Set<SyncEntityType>? only}) async {
    await _drainOnce();
    unawaited(_publish());
    for (final type in _pullOrder) {
      final adapter = _pullAdapters[type];
      if (adapter == null || (only != null && !only.contains(type))) continue;
      if (!force && !await _isStale(type)) continue;

      switch (await adapter.pullAll()) {
        case Ok():
          await _db.into(_db.syncCursors).insertOnConflictUpdate(
                SyncCursorsCompanion.insert(
                  entityType: type,
                  lastPulledAt: _clock(),
                ),
              );
          _diagnostics.log('pulled', data: {'entityType': type.name});
        case Err(:final error):
          // Not recorded as pulled, so the next trigger tries again.
          _diagnostics.log(
            'pull failed',
            data: {'entityType': type.name, 'error': error.message},
          );
      }
    }
  }

  Future<bool> _isStale(SyncEntityType type) async {
    final cursor = await (_db.select(_db.syncCursors)
          ..where((t) => t.entityType.equalsValue(type)))
        .getSingleOrNull();
    if (cursor == null) return true;
    return _clock().difference(cursor.lastPulledAt) >= pullInterval;
  }

  /// Makes every job that is waiting out a backoff due now.
  ///
  /// The app calls this when the connection returns. Wifi without internet
  /// counts as online, so pushes made there fail and back off for up to
  /// 30 minutes; a real reconnect is new evidence, and waiting out that
  /// schedule would leave the seller's changes sitting unsent. Rejected
  /// jobs stay parked: a reconnect does not change what the server refused.
  Future<void> retryNow() async {
    final now = _clock();
    await (_db.update(_db.outboxEntries)
          ..where(
            (t) =>
                t.lastError.isNotNull() &
                t.nextAttemptAt.isBiggerThanValue(now) &
                t.nextAttemptAt.equals(_parked).not(),
          ))
        .write(OutboxEntriesCompanion(nextAttemptAt: Value(now)));
  }

  /// Makes every rejected job due once more. The app calls this at launch,
  /// so a build that fixes how a body is made gets to send it.
  Future<void> releaseRejected() async {
    final released = await (_db.update(_db.outboxEntries)
          ..where((t) => t.nextAttemptAt.equals(_parked)))
        .write(OutboxEntriesCompanion(nextAttemptAt: Value(_clock())));
    if (released > 0) {
      _diagnostics.log('rejected released', data: {'count': released});
    }
  }

  /// Returns true when the job left the queue.
  Future<bool> _push(OutboxEntry entry) async {
    if (_recentlySynced.contains(entry.idempotencyKey)) {
      // Already delivered under this key; replaying is pointless.
      await _delete(entry);
      _diagnostics.log('skipped duplicate', data: {'id': entry.id});
      return true;
    }

    final outcome = await (_inFlight[entry.idempotencyKey] ??=
        _transport.push(entry).whenComplete(() {
      _inFlight.remove(entry.idempotencyKey);
    }));

    unawaited(_publish());
    switch (outcome) {
      case SyncPushSucceeded():
        _remember(entry.idempotencyKey);
        await _delete(entry);
        _diagnostics.log('pushed', data: {'id': entry.id});
        return true;

      case SyncPushRetryable(:final error):
        // The delete result is checked like any other. The old code
        // hardcoded ApiResponse(success: true) and lost the row.
        await _reschedule(entry, error);
        return false;

      case SyncPushRejected(:final error):
        // Keep the job and its reason rather than dropping it, and park it:
        // the same bytes would be refused again on every drain.
        await _recordRejection(entry, error);
        return false;
    }
  }

  Future<void> _delete(OutboxEntry entry) =>
      (_db.delete(_db.outboxEntries)..where((t) => t.id.equals(entry.id))).go();

  Future<void> _reschedule(OutboxEntry entry, String error) async {
    final attempts = entry.attemptCount + 1;
    final next = _clock().add(backoff.delayFor(attempts));
    await (_db.update(_db.outboxEntries)..where((t) => t.id.equals(entry.id)))
        .write(
      OutboxEntriesCompanion(
        attemptCount: Value(attempts),
        nextAttemptAt: Value(next),
        lastError: Value(error),
      ),
    );
    _diagnostics.log(
      'retry scheduled',
      data: {'id': entry.id, 'attempt': attempts, 'error': error},
    );
  }

  Future<void> _recordRejection(OutboxEntry entry, String error) async {
    await (_db.update(_db.outboxEntries)..where((t) => t.id.equals(entry.id)))
        .write(
      OutboxEntriesCompanion(
        attemptCount: Value(entry.attemptCount + 1),
        lastError: Value(error),
        nextAttemptAt: Value(_parked),
      ),
    );
    _diagnostics.log('rejected', data: {'id': entry.id, 'error': error});
  }

  void _remember(String key) {
    _recentlySynced
      ..remove(key)
      ..add(key);
    while (_recentlySynced.length > _recentLimit) {
      _recentlySynced.removeAt(0);
    }
  }
}
