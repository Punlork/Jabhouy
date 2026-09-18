import 'dart:async';

import 'package:drift/drift.dart';
import 'package:jabhouy_core/jabhouy_core.dart';
import 'package:jabhouy_sync/src/backoff.dart';
import 'package:jabhouy_sync/src/transport.dart';

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
    int recentFingerprintLimit = 200,
  })  : _db = database,
        _transport = transport,
        _diagnostics = diagnostics,
        _clock = clock,
        _recentLimit = recentFingerprintLimit;

  final AppDatabase _db;
  final SyncTransport _transport;
  final SyncDiagnostics _diagnostics;
  final DateTime Function() _clock;
  final int _recentLimit;

  final BackoffPolicy backoff;

  /// Pushes in flight, keyed by fingerprint.
  ///
  /// Two drains racing on the same job join the same future instead of
  /// sending it twice, as `_inFlightNotificationSyncs` does for income.
  final Map<String, Future<SyncPushOutcome>> _inFlight = {};

  /// Fingerprints that recently succeeded, oldest first.
  ///
  /// Bounded, like income's `_rememberSyncedFingerprint` at 200 entries: an
  /// unbounded set would grow for the life of the process.
  final _recentlySynced = <String>[];

  /// Queues a write, or folds it into the job already waiting for that row.
  ///
  /// A second edit before the first reaches the server is still one push.
  Future<void> enqueue({
    required SyncEntityType entityType,
    required String entityLocalId,
    required SyncOperation operation,
    required String fingerprint,
    String? dependsOnLocalId,
  }) async {
    await _db.into(_db.outboxEntries).insert(
          OutboxEntriesCompanion.insert(
            entityType: entityType,
            entityLocalId: entityLocalId,
            operation: operation,
            fingerprint: fingerprint,
            dependsOnLocalId: Value(dependsOnLocalId),
            nextAttemptAt: Value(_clock()),
          ),
          // Fold into the job already waiting for this row. The default
          // conflict target is the primary key, which is not the constraint
          // that expresses "one live job per row".
          onConflict: DoUpdate<$OutboxEntriesTable, OutboxEntry>(
            (_) => OutboxEntriesCompanion(
              operation: Value(operation),
              fingerprint: Value(fingerprint),
              dependsOnLocalId: Value(dependsOnLocalId),
              // A fresh edit supersedes the old bytes, so the previous
              // failure and its schedule no longer apply.
              attemptCount: const Value(0),
              lastError: const Value(null),
              nextAttemptAt: Value(_clock()),
            ),
            target: [
              _db.outboxEntries.entityType,
              _db.outboxEntries.entityLocalId,
            ],
          ),
        );
    _diagnostics.log(
      'enqueued',
      data: {
        'entityType': entityType.name,
        'entityLocalId': entityLocalId,
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
        .map((e) => e.entityLocalId)
        .toSet();

    return due
        .where(
          (e) =>
              e.dependsOnLocalId == null ||
              !queuedIds.contains(e.dependsOnLocalId),
        )
        .toList();
  }

  /// Pushes due jobs until no further progress is possible.
  ///
  /// Repeats because clearing a job makes anything that depended on it
  /// eligible: a category leaving the queue releases its shop items in the
  /// same drain rather than the next one. Each pass that clears nothing
  /// ends the loop, and jobs only ever leave the queue, so it terminates.
  Future<int> drain() async {
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

  /// Returns true when the job left the queue.
  Future<bool> _push(OutboxEntry entry) async {
    if (_recentlySynced.contains(entry.fingerprint)) {
      // Already delivered under this fingerprint; replaying is pointless.
      await _delete(entry);
      _diagnostics.log('skipped duplicate', data: {'id': entry.id});
      return true;
    }

    final outcome = await (_inFlight[entry.fingerprint] ??=
        _transport.push(entry).whenComplete(() {
      _inFlight.remove(entry.fingerprint);
    }));

    switch (outcome) {
      case SyncPushSucceeded():
        _remember(entry.fingerprint);
        await _delete(entry);
        _diagnostics.log('pushed', data: {'id': entry.id});
        return true;

      case SyncPushFailedTransiently(:final error):
        // The delete result is checked like any other. The old code
        // hardcoded ApiResponse(success: true) and lost the row.
        await _reschedule(entry, error);
        return false;

      case SyncPushRejected(:final error):
        // Retrying sends identical bytes, so stop advancing the schedule
        // but keep the job and its reason rather than dropping it.
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
      ),
    );
    _diagnostics.log('rejected', data: {'id': entry.id, 'error': error});
  }

  void _remember(String fingerprint) {
    _recentlySynced
      ..remove(fingerprint)
      ..add(fingerprint);
    while (_recentlySynced.length > _recentLimit) {
      _recentlySynced.removeAt(0);
    }
  }
}
