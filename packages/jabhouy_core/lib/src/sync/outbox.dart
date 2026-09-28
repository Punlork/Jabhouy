import 'package:drift/drift.dart';

/// Which table an outbox job belongs to.
///
/// Names match the model classes already in the app, so a reader meets no
/// new vocabulary.
enum SyncEntityType { shopItem, category, customer, loaner, bankNotification }

/// What an outbox job will do to the server.
enum SyncOperation { create, update, delete }

/// One row per write waiting to reach the server.
///
/// This replaces `syncStatus` as the queue. `syncStatus` described a row;
/// this describes a job, which is what lets it carry an attempt count, a
/// schedule and a dependency -- none of which fit on a status column.
///
/// The index supports the only hot path: due jobs for one entity type.
@TableIndex(name: 'outbox_drain_idx', columns: {#entityType, #nextAttemptAt})
class OutboxEntries extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get entityType => textEnum<SyncEntityType>()();

  /// The local key of the row this job is about.
  ///
  /// Text rather than integer because entity tables are moving to UUID
  /// primary keys; until then this holds the stringified integer id.
  TextColumn get localId => text()();

  TextColumn get operation => textEnum<SyncOperation>()();

  /// The value that makes replaying this job safe: push it twice under the
  /// same key and the server is expected to admit it once.
  ///
  /// Generalises `BankNotifications.fingerprint`, which is the one
  /// idempotency guarantee the app already relies on. Named for the job it
  /// does rather than for its shape -- a fingerprint of the notification
  /// text is what income happens to use as its key, not what the column
  /// means here.
  TextColumn get idempotencyKey => text()();

  /// How many pushes this job has survived. Drives the backoff schedule.
  IntColumn get attemptCount => integer().withDefault(const Constant(0))();

  /// The earliest time the drain loop may pick this job up again.
  DateTimeColumn get nextAttemptAt =>
      dateTime().withDefault(currentDateAndTime)();

  /// Why the last attempt failed.
  ///
  /// Replaces the `catch (_)` blocks that collapsed every distinct failure
  /// into one status integer.
  TextColumn get lastError => text().nullable()();

  /// The [localId] this job must wait for.
  ///
  /// Orders a shop item after the offline category it references.
  TextColumn get dependsOnLocalId => text().nullable()();

  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();

  /// One live job per entity row. A second write to the same row updates
  /// the existing job rather than queueing a duplicate push.
  @override
  List<Set<Column>> get uniqueKeys => [
        {entityType, localId},
      ];
}

/// Where each entity's last pull left off.
///
/// The server cannot say what changed, so a pull downloads everything and
/// [lastPulledAt] only decides whether it is due. [cursor] is where an
/// `updatedSince` value goes once the server offers one.
class SyncCursors extends Table {
  TextColumn get entityType => textEnum<SyncEntityType>()();

  /// When the last complete pull of this entity succeeded.
  DateTimeColumn get lastPulledAt => dateTime()();

  TextColumn get cursor => text().nullable()();

  @override
  Set<Column> get primaryKey => {entityType};
}
