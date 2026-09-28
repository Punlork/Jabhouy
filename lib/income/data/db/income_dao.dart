import 'package:drift/drift.dart';
import 'package:jabhouy/income/models/bank_notification_model.dart';
import 'package:jabhouy_core/jabhouy_core.dart';

/// Every Drift statement the income feature issues.
///
/// A plain class rather than a `@DriftAccessor`, for the reason given on
/// `ShopDao`.
class IncomeDao {
  const IncomeDao(this._db);

  final AppDatabase _db;

  Stream<List<BankNotificationModel>> watchNotifications({
    String searchQuery = '',
    DateTime? fromDate,
    DateTime? toDate,
    BankApp? bankFilter,
    NotificationRecordFilter recordFilter = NotificationRecordFilter.all,
  }) {
    final query = _db.select(_db.bankNotifications);

    if (searchQuery.isNotEmpty) {
      query.where(
        (tbl) =>
            tbl.message.contains(searchQuery) |
            tbl.bankKey.contains(searchQuery) |
            tbl.packageName.contains(searchQuery) |
            tbl.title.contains(searchQuery),
      );
    }

    if (fromDate != null) {
      query.where((tbl) => tbl.receivedAt.isBiggerOrEqualValue(fromDate));
    }

    if (toDate != null) {
      final endOfDay =
          DateTime(toDate.year, toDate.month, toDate.day, 23, 59, 59, 999);
      query.where((tbl) => tbl.receivedAt.isSmallerOrEqualValue(endOfDay));
    }

    if (bankFilter != null && bankFilter != BankApp.unknown) {
      query.where((tbl) => tbl.bankKey.equals(bankFilter.key));
    }

    switch (recordFilter) {
      case NotificationRecordFilter.income:
        query.where((tbl) => tbl.isIncome.equals(true));
      case NotificationRecordFilter.expense:
        query.where((tbl) => tbl.isIncome.equals(false));
      case NotificationRecordFilter.all:
        break;
    }

    query.orderBy([
      (tbl) =>
          OrderingTerm(expression: tbl.receivedAt, mode: OrderingMode.desc),
      (tbl) => OrderingTerm(expression: tbl.id, mode: OrderingMode.desc),
    ]);

    return query
        .watch()
        .map((rows) => rows.map(toModel).toList(growable: false));
  }

  Future<BankNotificationModel?> findByFingerprint(String fingerprint) async {
    final row = await (_db.select(_db.bankNotifications)
          ..where((tbl) => tbl.fingerprint.equals(fingerprint)))
        .getSingleOrNull();
    return row == null ? null : toModel(row);
  }

  /// Everything the server has not acknowledged.
  ///
  /// `failed` is included deliberately. This is the one query in the app
  /// that always read it, and the reason income is the only sync path that
  /// does not lose writes: the other four selected `pending` alone, so a
  /// row that failed once was never looked at again.
  Future<List<BankNotificationModel>> pendingNotifications() async {
    final rows = await (_db.select(_db.bankNotifications)
          ..where(
            (tbl) =>
                tbl.syncStatus.equalsValue(SyncStatus.pending) |
                tbl.syncStatus.equalsValue(SyncStatus.failed),
          )
          ..orderBy([
            (tbl) => OrderingTerm(
                  expression: tbl.receivedAt,
                  mode: OrderingMode.desc,
                ),
          ]))
        .get();

    return rows.map(toModel).toList(growable: false);
  }

  /// Returns true when the row is new.
  ///
  /// A row is `pending` until a push confirms otherwise. A caller that
  /// does push overwrites this immediately after; a caller that does not
  /// never revisits it, so writing `synced` here would claim an upload
  /// that never happened.
  Future<bool> upsert(
    BankNotificationModel model, {
    String? rawPayloadOverride,
  }) async {
    final existing = await (_db.select(_db.bankNotifications)
          ..where((tbl) => tbl.fingerprint.equals(model.fingerprint)))
        .getSingleOrNull();

    if (existing == null) {
      await _db.into(_db.bankNotifications).insert(
            BankNotificationsCompanion.insert(
              fingerprint: model.fingerprint,
              packageName: model.packageName,
              bankKey: model.bankApp.key,
              title: Value(model.title),
              message: model.message,
              rawPayload: Value(rawPayloadOverride ?? model.rawPayload),
              amount: Value(model.amount),
              currency: Value(model.currency),
              isIncome: Value(model.isIncome),
              receivedAt: model.receivedAt,
              source: Value(model.source),
              syncStatus: const Value(SyncStatus.pending),
              createdAt: Value(model.createdAt),
            ),
          );
      return true;
    }

    await (_db.update(_db.bankNotifications)
          ..where((tbl) => tbl.id.equals(existing.id)))
        .write(
      BankNotificationsCompanion(
        packageName: Value(model.packageName),
        bankKey: Value(model.bankApp.key),
        title: Value(model.title),
        message: Value(model.message),
        rawPayload: Value(rawPayloadOverride ?? model.rawPayload),
        amount: Value(model.amount),
        currency: Value(model.currency),
        isIncome: Value(model.isIncome),
        receivedAt: Value(model.receivedAt),
        source: Value(model.source),
        // Untouched: an edit to the body is not an upload.
        syncStatus: Value(existing.syncStatus),
        createdAt: Value(model.createdAt),
      ),
    );
    return false;
  }

  Future<void> updateSyncStatus(String fingerprint, SyncStatus status) {
    return (_db.update(_db.bankNotifications)
          ..where((tbl) => tbl.fingerprint.equals(fingerprint)))
        .write(BankNotificationsCompanion(syncStatus: Value(status)));
  }

  /// Rows stored before the parser could read their bank or amount.
  Future<List<BankNotification>> rowsNeedingBackfill() {
    return (_db.select(_db.bankNotifications)
          ..where(
            (tbl) =>
                tbl.bankKey.equals(BankApp.unknown.key) | tbl.amount.isNull(),
          ))
        .get();
  }

  Future<void> applyBackfill(
    int id, {
    Value<String> bankKey = const Value.absent(),
    Value<double?> amount = const Value.absent(),
    Value<String> currency = const Value.absent(),
  }) {
    return (_db.update(_db.bankNotifications)..where((tbl) => tbl.id.equals(id)))
        .write(
      BankNotificationsCompanion(
        bankKey: bankKey,
        amount: amount,
        currency: currency,
      ),
    );
  }

  static BankNotificationModel toModel(BankNotification row) {
    return BankNotificationModel(
      id: row.id,
      fingerprint: row.fingerprint,
      packageName: row.packageName,
      bankApp: BankApp.fromKey(row.bankKey),
      title: row.title,
      message: row.message,
      rawPayload: row.rawPayload,
      amount: row.amount,
      currency: row.currency,
      isIncome: row.isIncome,
      receivedAt: row.receivedAt,
      source: row.source,
      createdAt: row.createdAt,
    );
  }
}
