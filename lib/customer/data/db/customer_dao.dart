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

  Future<void> cacheServerCustomers(List<CustomerModel> customers) {
    return _db.batch((batch) {
      batch.insertAll(
        _db.customers,
        customers.map((c) => _companion(c, SyncStatus.synced)),
        mode: InsertMode.insertOrReplace,
      );
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
