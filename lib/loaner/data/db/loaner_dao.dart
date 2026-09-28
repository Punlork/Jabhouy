import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:jabhouy/customer/customer.dart';
import 'package:jabhouy/loaner/loaner.dart';
import 'package:jabhouy_core/jabhouy_core.dart';

/// Every Drift statement the loaner feature issues.
///
/// A plain class rather than a `@DriftAccessor`, for the reason given on
/// `ShopDao`.
class LoanerDao {
  const LoanerDao(this._db);

  final AppDatabase _db;

  Stream<List<LoanerModel>> watchLoaners({
    String searchQuery = '',
    CustomerModel? customerFilter,
    DateTime? fromDate,
    DateTime? toDate,
  }) {
    final query = _filtered(
      searchQuery: searchQuery,
      customerFilter: customerFilter,
      fromDate: fromDate,
      toDate: toDate,
    )..orderBy([
        OrderingTerm(
          expression: _db.loaners.createdAt,
          mode: OrderingMode.desc,
        ),
        OrderingTerm(expression: _db.loaners.id, mode: OrderingMode.desc),
      ]);

    return query.watch().map(
          (rows) => rows
              .map(
                (row) => _toModel(
                  row.readTable(_db.loaners),
                  row.readTableOrNull(_db.customers),
                ),
              )
              .toList(),
        );
  }

  Future<bool> hasCachedLoaners({
    String searchQuery = '',
    CustomerModel? customerFilter,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    final query = _filtered(
      searchQuery: searchQuery,
      customerFilter: customerFilter,
      fromDate: fromDate,
      toDate: toDate,
    )..limit(1);
    return (await query.get()).isNotEmpty;
  }

  Future<LoanerModel?> findById(int id) async {
    final row = await (_db.select(_db.loaners)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    return row == null ? null : _toModel(row);
  }

  /// Writes a page of server rows, skipping any row with a queued job.
  ///
  /// Writing over those would put the server's older copy where the
  /// seller's unsent edit was, and the queued job, which re-reads the row,
  /// would then send that older copy. A queued delete would come back.
  Future<void> cacheServerLoaners(List<LoanerModel> loaners) {
    return _db.transaction(() async {
      // Read inside the transaction, so an edit cannot land between the
      // check and the write.
      final queued = await _db.queuedLocalIds(SyncEntityType.loaner);
      await _db.batch((batch) {
        batch.insertAll(
          _db.loaners,
          loaners
              .where((l) => !queued.contains('${l.id}'))
              .map((l) => _companion(l, SyncStatus.synced)),
          mode: InsertMode.insertOrReplace,
        );
      });
    });
  }

  Future<void> insertPending(LoanerModel loaner) {
    return _db.into(_db.loaners).insert(
          _companion(loaner, SyncStatus.pending),
          mode: InsertMode.insertOrReplace,
        );
  }

  Future<void> replace(LoanerModel loaner, SyncStatus status) {
    return _db.update(_db.loaners).replace(_row(loaner, status));
  }

  Future<void> markDeletedPending(int id) {
    return (_db.update(_db.loaners)..where((t) => t.id.equals(id))).write(
      const LoanersCompanion(
        isDeleted: Value(true),
        syncStatus: Value(SyncStatus.pending),
      ),
    );
  }

  Future<void> markFailed(int id) {
    return (_db.update(_db.loaners)..where((t) => t.id.equals(id))).write(
      const LoanersCompanion(syncStatus: Value(SyncStatus.failed)),
    );
  }

  Future<void> purge(int id) {
    return (_db.delete(_db.loaners)..where((t) => t.id.equals(id))).go();
  }

  /// Swaps a locally-minted negative id for the server's, in one
  /// transaction.
  ///
  /// Nothing references `Loaners.id`, so unlike category and customer this
  /// reconciliation has no foreign key to repoint. Loaner is the leaf.
  Future<void> reconcileCreated({
    required int localId,
    required LoanerModel serverLoaner,
  }) {
    return _db.transaction(() async {
      await purge(localId);
      await _db.into(_db.loaners).insert(
            _companion(serverLoaner, SyncStatus.synced),
            mode: InsertMode.insertOrReplace,
          );
    });
  }

  JoinedSelectStatement<HasResultSet, dynamic> _filtered({
    required String searchQuery,
    required CustomerModel? customerFilter,
    required DateTime? fromDate,
    required DateTime? toDate,
  }) {
    final query = _db.select(_db.loaners).join([
      leftOuterJoin(
        _db.customers,
        _db.customers.id.equalsExp(_db.loaners.customerId) &
            _db.customers.isDeleted.equals(false),
      ),
    ])
      ..where(_db.loaners.isDeleted.equals(false));

    if (searchQuery.isNotEmpty) {
      query.where(
        _db.customers.name.contains(searchQuery) |
            _db.loaners.note.contains(searchQuery),
      );
    }

    if (customerFilter != null) {
      query.where(_db.loaners.customerId.equals(customerFilter.id));
    }

    if (fromDate != null) {
      query.where(_db.loaners.createdAt.isBiggerOrEqualValue(fromDate));
    }

    if (toDate != null) {
      final endOfDay =
          DateTime(toDate.year, toDate.month, toDate.day, 23, 59, 59, 999);
      query.where(_db.loaners.createdAt.isSmallerOrEqualValue(endOfDay));
    }

    return query;
  }

  LoanerModel _toModel(Loaner loaner, [Customer? joined]) {
    final customer = decodeCustomer(loaner.customer) ?? _mapCustomer(joined);
    return LoanerModel(
      id: loaner.id,
      amount: loaner.amount,
      note: loaner.note,
      // Falls back to the blob for rows written before fromJson read the
      // nested id, so their queued pushes stop failing with a 400.
      customerId: loaner.customerId ?? customer?.id,
      isPaid: loaner.isPaid,
      createdAt: loaner.createdAt,
      updatedAt: loaner.updatedAt,
      syncStatus: loaner.syncStatus,
      isDeleted: loaner.isDeleted,
      // The denormalised blob wins over the join: it is the customer as
      // the server described it on this loan, and it survives the
      // customer row being deleted.
      customer: customer,
    );
  }

  CustomerModel? _mapCustomer(Customer? customer) {
    if (customer == null || customer.isDeleted) return null;
    return CustomerModel(
      id: customer.id,
      name: customer.name,
      createdAt: customer.createdAt,
      updatedAt: customer.updatedAt,
      syncStatus: customer.syncStatus,
      isDeleted: customer.isDeleted,
    );
  }

  LoanersCompanion _companion(LoanerModel l, SyncStatus status) {
    return LoanersCompanion.insert(
      id: Value(l.id),
      amount: l.amount,
      note: Value(l.note),
      customerId: Value(l.customerId),
      customer: Value(encodeCustomer(l.customer)),
      isPaid: Value(l.isPaid),
      createdAt: l.createdAt,
      updatedAt: Value(l.updatedAt),
      syncStatus: Value(status),
      isDeleted: Value(l.isDeleted),
    );
  }

  Loaner _row(LoanerModel l, SyncStatus status) {
    return Loaner(
      id: l.id,
      amount: l.amount,
      note: l.note,
      customerId: l.customerId,
      customer: encodeCustomer(l.customer),
      isPaid: l.isPaid,
      createdAt: l.createdAt,
      updatedAt: l.updatedAt,
      syncStatus: status,
      isDeleted: l.isDeleted,
    );
  }
}

/// `Loaners.customer` is a denormalised JSON copy of the customer as the
/// server described it on that loan. These two are the only places that
/// know its shape.
String? encodeCustomer(CustomerModel? customer) {
  if (customer == null) return null;
  return jsonEncode({
    'id': customer.id,
    'name': customer.name,
    if (customer.createdAt != null)
      'createdAt': customer.createdAt!.toIso8601String(),
    if (customer.updatedAt != null)
      'updatedAt': customer.updatedAt!.toIso8601String(),
    'syncStatus': customer.syncStatus.wireValue,
    'isDeleted': customer.isDeleted,
  });
}

CustomerModel? decodeCustomer(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  final decoded = jsonDecode(raw);
  if (decoded is! Map<String, dynamic>) return null;
  return CustomerModel.fromJson(decoded);
}
