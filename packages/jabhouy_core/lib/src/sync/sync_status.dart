import 'package:drift/drift.dart';

/// Where a row stands relative to the server.
///
/// Stored as the same integer the schema has always used, so adopting this
/// enum needs no migration. The values are fixed by that history and must
/// not be renumbered.
enum SyncStatus {
  /// The server holds this row as it currently stands locally.
  synced(0),

  /// The row has local changes that have not reached the server yet.
  pending(1),

  /// A push was attempted and failed.
  ///
  /// Terminal today. The outbox engine makes it retryable.
  failed(2);

  const SyncStatus(this.wireValue);

  /// The integer written to SQLite. Fixed by the existing schema.
  final int wireValue;

  /// Reads a stored integer.
  ///
  /// An unrecognised value resolves to [pending] rather than [synced]. A row
  /// we cannot classify has no proof it ever reached the server, and calling
  /// it synced is how writes get dropped silently.
  static SyncStatus fromWireValue(int value) => switch (value) {
        0 => SyncStatus.synced,
        2 => SyncStatus.failed,
        _ => SyncStatus.pending,
      };
}

/// Maps [SyncStatus] onto the integer column the schema already has.
class SyncStatusConverter extends TypeConverter<SyncStatus, int>
    with JsonTypeConverter<SyncStatus, int> {
  const SyncStatusConverter();

  @override
  SyncStatus fromSql(int fromDb) => SyncStatus.fromWireValue(fromDb);

  @override
  int toSql(SyncStatus value) => value.wireValue;
}
