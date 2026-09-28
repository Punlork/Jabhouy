import 'package:drift/drift.dart';
import 'package:jabhouy/customer/customer.dart';
import 'package:jabhouy_core/jabhouy_core.dart';

/// Every Drift statement the customer feature issues.
///
/// A plain class rather than a `@DriftAccessor`, for the reason given on
/// `ShopDao`.
class CustomerDao {
  const CustomerDao(this._db);

  final AppDatabase _db;

  Stream<List<CustomerModel>> watchCustomers() {
    return (_db.select(_db.customers)..where((t) => t.isDeleted.equals(false)))
        .watch()
        .map((rows) => rows.map(_toModel).toList());
  }

  Future<CustomerModel?> findById(int id) async {
    final row = await (_db.select(_db.customers)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    return row == null ? null : _toModel(row);
  }

  Future<bool> hasCachedCustomers() async {
    final query = _db.select(_db.customers)
      ..where((t) => t.isDeleted.equals(false))
      ..limit(1);
    return (await query.get()).isNotEmpty;
  }

  /// Writes one page of server rows, as the old per-load refresh does.
  /// A page is never the whole list, so it deletes nothing.
  Future<void> cacheServerCustomers(List<CustomerModel> customers) =>
      reconcileServerCustomers(customers, complete: false);

  /// Writes server rows, skipping any row with a queued job.
  ///
  /// Writing over those would put the server's older copy where the
  /// seller's unsent edit was, and the queued job, which re-reads the row,
  /// would then send that older copy. A queued delete would come back.
  ///
  /// With [complete], [customers] is everything the server holds, so a row it
  /// did not return was deleted there and goes here too — unless it has a
  /// queued job, or a negative id, which means the server never had it.
  Future<void> reconcileServerCustomers(
    List<CustomerModel> customers, {
    required bool complete,
  }) {
    return _db.transaction(() async {
      // Read inside the transaction, so an edit cannot land between the
      // check and the write.
      final queued = await _db.queuedLocalIds(SyncEntityType.customer);
      await _db.batch((batch) {
        batch.insertAll(
          _db.customers,
          customers
              .where((c) => !queued.contains('${c.id}'))
              .map((c) => _companion(c, SyncStatus.synced)),
          mode: InsertMode.insertOrReplace,
        );
      });
      if (!complete) return;

      final onServer = customers.map((c) => c.id).toList();
      final keep = queued.map(int.tryParse).whereType<int>().toList();
      await (_db.customers.delete()
            ..where(
              (t) =>
                  t.id.isBiggerThanValue(0) &
                  t.id.isNotIn(onServer) &
                  t.id.isNotIn(keep),
            ))
          .go();
    });
  }

  Future<void> insertPending(CustomerModel customer) {
    return _db.into(_db.customers).insert(
          _companion(customer, SyncStatus.pending),
          mode: InsertMode.insertOrReplace,
        );
  }

  Future<void> replace(CustomerModel customer, SyncStatus status) {
    return _db.update(_db.customers).replace(
          Customer(
            id: customer.id,
            name: customer.name,
            createdAt: customer.createdAt,
            updatedAt: customer.updatedAt,
            syncStatus: status,
            isDeleted: customer.isDeleted,
          ),
        );
  }

  Future<void> markDeletedPending(int id) {
    return (_db.update(_db.customers)..where((t) => t.id.equals(id))).write(
      const CustomersCompanion(
        isDeleted: Value(true),
        syncStatus: Value(SyncStatus.pending),
      ),
    );
  }

  Future<void> markFailed(int id) {
    return (_db.update(_db.customers)..where((t) => t.id.equals(id))).write(
      const CustomersCompanion(syncStatus: Value(SyncStatus.failed)),
    );
  }

  Future<void> purge(int id) {
    return (_db.delete(_db.customers)..where((t) => t.id.equals(id))).go();
  }

  /// Swaps a locally-minted negative id for the server's, and repoints
  /// every loaner that referenced the local id.
  ///
  /// Same shape as `CategoryDao.reconcileCreated` and for the same reason:
  /// `Loaners.customerId` references `Customers.id`, so the swap has to
  /// fix a foreign key, and all of it has to be one transaction.
  Future<void> reconcileCreated({
    required int localId,
    required CustomerModel serverCustomer,
  }) {
    return _db.transaction(() async {
      await _db.into(_db.customers).insert(
            _companion(serverCustomer, SyncStatus.synced),
            mode: InsertMode.insertOrReplace,
          );
      await (_db.update(_db.loaners)
            ..where((t) => t.customerId.equals(localId)))
          .write(LoanersCompanion(customerId: Value(serverCustomer.id)));
      await purge(localId);
    });
  }

  CustomerModel _toModel(Customer row) {
    return CustomerModel(
      id: row.id,
      name: row.name,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      syncStatus: row.syncStatus,
      isDeleted: row.isDeleted,
    );
  }

  CustomersCompanion _companion(CustomerModel c, SyncStatus status) {
    return CustomersCompanion.insert(
      id: Value(c.id),
      name: c.name,
      createdAt: Value(c.createdAt ?? DateTime.now()),
      updatedAt: Value(c.updatedAt ?? DateTime.now()),
      syncStatus: Value(status),
      isDeleted: Value(c.isDeleted),
    );
  }
}
