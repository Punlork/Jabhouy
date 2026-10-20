import 'package:drift/drift.dart';
import 'package:jabhouy/credit/models/credit.dart';
import 'package:jabhouy_core/jabhouy_core.dart';

/// What the picker needs from one Customer row before balances are summed.
typedef CustomerRows = ({
  CreditCustomer customer,
  int creditCount,
  List<({Currency currency, int? amount, int khrPerUsd})> unpaid,
});

/// Drift queries for redesign Customers and Credits. Every read is scoped
/// to one Shop and skips deleted rows.
class CreditDao {
  CreditDao(this._db);

  final AppDatabase _db;

  /// Live Credits, newest first, without their lines.
  Stream<List<Credit>> watchCredits(String shopId) {
    final query = _db.select(_db.creditTable).join([
      innerJoin(
        _db.customerTable,
        _db.customerTable.id.equalsExp(_db.creditTable.customerId),
      ),
    ])
      ..where(
        _db.creditTable.shopId.equals(shopId) &
            _db.creditTable.deletedAt.isNull(),
      )
      ..orderBy([OrderingTerm.desc(_db.creditTable.takenAt)]);
    return query.watch().map(
      (rows) => [
        for (final row in rows)
          _credit(
            row.readTable(_db.creditTable),
            row.readTable(_db.customerTable).name,
            const [],
          ),
      ],
    );
  }

  /// The live Credit with its lines, or null once deleted.
  Future<Credit?> creditById(String id) async {
    final row =
        await (_db.select(_db.creditTable)
              ..where((c) => c.id.equals(id) & c.deletedAt.isNull()))
            .getSingleOrNull();
    if (row == null) return null;
    final customer =
        await (_db.select(_db.customerTable)
              ..where((c) => c.id.equals(row.customerId)))
            .getSingleOrNull();
    final lines = await (_db.select(_db.creditItemTable)
          ..where((l) => l.creditId.equals(id)))
        .get();
    return _credit(row, customer?.name ?? '', [for (final l in lines) _line(l)]);
  }

  /// Writes the Credit and replaces its lines. One transaction.
  Future<void> saveCredit(
    String shopId,
    Credit credit, {
    required DateTime now,
    String? userId,
  }) => _db.transaction(() async {
    await _db.into(_db.creditTable).insertOnConflictUpdate(
          CreditTableCompanion.insert(
            id: credit.id,
            shopId: shopId,
            customerId: credit.customerId,
            currency: credit.currency.name.toUpperCase(),
            amount: Value(credit.amount),
            khrPerUsd: credit.khrPerUsd,
            status: credit.status.name,
            takenAt: credit.takenAt.toUtc(),
            dueDate: Value(credit.dueDate),
            paidAt: Value(credit.paidAt?.toUtc()),
            note: Value(credit.note),
            updatedAt: Value(now),
            updatedBy: Value(userId),
            deletedAt: const Value(null),
          ),
        );
    await _replaceLines(credit.id, credit.lines);
  });

  Future<void> markCreditDeleted(String id, DateTime now, String? userId) =>
      (_db.update(_db.creditTable)..where((c) => c.id.equals(id))).write(
        CreditTableCompanion(
          deletedAt: Value(now),
          updatedAt: Value(now),
          updatedBy: Value(userId),
        ),
      );

  Future<void> _replaceLines(String creditId, List<CreditLine> lines) async {
    await (_db.delete(_db.creditItemTable)
          ..where((l) => l.creditId.equals(creditId)))
        .go();
    for (final l in lines) {
      await _db.into(_db.creditItemTable).insert(
            CreditItemTableCompanion.insert(
              id: l.id,
              creditId: creditId,
              priceId: Value(l.priceId),
              name: l.name,
              unit: l.unit,
              qty: l.qty,
              currency: l.currency.name.toUpperCase(),
              unitPrice: l.unitPrice,
              total: l.unitPrice * l.qty,
            ),
          );
    }
  }

  // Customers.

  /// Live Customers, A–Z, each with how many Credits they have and their
  /// unpaid ones; re-emits when either table changes.
  Stream<List<CustomerRows>> watchCustomers(String shopId) => _db
      .customSelect(
        '''
        SELECT c.id, c.name, c.phone, c.note,
               (SELECT COUNT(*) FROM credit x
                 WHERE x.customer_id = c.id AND x.deleted_at IS NULL)
                 AS credit_count,
               u.currency AS u_currency, u.amount AS u_amount,
               u.khr_per_usd AS u_rate
        FROM customer c
        LEFT JOIN credit u
          ON u.customer_id = c.id AND u.deleted_at IS NULL
         AND u.status = 'unpaid'
        WHERE c.shop_id = ? AND c.deleted_at IS NULL
        ORDER BY c.name COLLATE NOCASE, c.id
        ''',
        variables: [Variable.withString(shopId)],
        readsFrom: {_db.customerTable, _db.creditTable},
      )
      .watch()
      .map(_customersFrom);

  List<CustomerRows> _customersFrom(List<QueryRow> rows) {
    final byId = <String, CustomerRows>{};
    for (final row in rows) {
      final id = row.read<String>('id');
      final entry = byId.putIfAbsent(
        id,
        () => (
          customer: CreditCustomer(
            id: id,
            name: row.read<String>('name'),
            phone: row.readNullable<String>('phone'),
            note: row.readNullable<String>('note'),
          ),
          creditCount: row.read<int>('credit_count'),
          unpaid: [],
        ),
      );
      final currency = row.readNullable<String>('u_currency');
      if (currency != null) {
        entry.unpaid.add((
          currency: _currency(currency),
          amount: row.readNullable<int>('u_amount'),
          khrPerUsd: row.read<int>('u_rate'),
        ));
      }
    }
    return byId.values.toList();
  }

  Future<CreditCustomer?> customerById(String id) async {
    final row =
        await (_db.select(_db.customerTable)
              ..where((c) => c.id.equals(id) & c.deletedAt.isNull()))
            .getSingleOrNull();
    return row == null ? null : _customer(row);
  }

  Future<void> saveCustomer(
    String shopId,
    CreditCustomer customer, {
    required DateTime now,
    String? userId,
  }) => _db.into(_db.customerTable).insertOnConflictUpdate(
        CustomerTableCompanion.insert(
          id: customer.id,
          shopId: shopId,
          name: customer.name,
          phone: Value(customer.phone),
          note: Value(customer.note),
          updatedAt: Value(now),
          updatedBy: Value(userId),
          deletedAt: const Value(null),
        ),
      );

  Future<void> markCustomerDeleted(String id, DateTime now, String? userId) =>
      (_db.update(_db.customerTable)..where((c) => c.id.equals(id))).write(
        CustomerTableCompanion(
          deletedAt: Value(now),
          updatedAt: Value(now),
          updatedBy: Value(userId),
        ),
      );

  /// Live Credits of [customerId], paid or not.
  Future<int> creditCount(String customerId) async {
    final count = _db.creditTable.id.count();
    final query = _db.selectOnly(_db.creditTable)
      ..addColumns([count])
      ..where(
        _db.creditTable.customerId.equals(customerId) &
            _db.creditTable.deletedAt.isNull(),
      );
    return (await query.getSingle()).read(count)!;
  }

  // The Shop's settings, for a new Credit's snapshot and the balances.

  Future<({Currency currency, int khrPerUsd})> rates(String shopId) async {
    final row =
        await (_db.select(_db.shopSettingsTable)
              ..where((s) => s.shopId.equals(shopId)))
            .getSingleOrNull();
    return (
      currency: row == null ? Currency.khr : _currency(row.defaultCurrency),
      khrPerUsd: row?.khrPerUsd ?? 4000,
    );
  }

  // Server rows (`/changes`).

  Future<void> applyCustomers(
    String shopId,
    List<Map<String, Object?>> rows,
    Set<String> skip,
  ) async {
    for (final row in rows) {
      final id = row['id']! as String;
      if (skip.contains(id)) continue;
      final at = _time(row['updatedAt']);
      final by = row['updatedBy'] as String?;
      final seq = (row['seq'] as int?) ?? 0;
      if (row['deletedAt'] != null) {
        await (_db.update(_db.customerTable)..where((c) => c.id.equals(id)))
            .write(
          CustomerTableCompanion(
            deletedAt: Value(_time(row['deletedAt'])),
            updatedAt: Value(at),
            updatedBy: Value(by),
            seq: Value(seq),
          ),
        );
        continue;
      }
      await _db.into(_db.customerTable).insertOnConflictUpdate(
            CustomerTableCompanion.insert(
              id: id,
              shopId: shopId,
              name: row['name']! as String,
              phone: Value(row['phone'] as String?),
              note: Value(row['note'] as String?),
              updatedAt: Value(at),
              updatedBy: Value(by),
              deletedAt: const Value(null),
              seq: Value(seq),
            ),
          );
    }
  }

  Future<void> applyCredits(
    String shopId,
    List<Map<String, Object?>> rows,
    Set<String> skip,
  ) async {
    for (final row in rows) {
      final id = row['id']! as String;
      if (skip.contains(id)) continue;
      final at = _time(row['updatedAt']);
      final by = row['updatedBy'] as String?;
      final seq = (row['seq'] as int?) ?? 0;
      if (row['deletedAt'] != null) {
        await (_db.update(_db.creditTable)..where((c) => c.id.equals(id)))
            .write(
          CreditTableCompanion(
            deletedAt: Value(_time(row['deletedAt'])),
            updatedAt: Value(at),
            updatedBy: Value(by),
            seq: Value(seq),
          ),
        );
        continue;
      }
      await _db.into(_db.creditTable).insertOnConflictUpdate(
            CreditTableCompanion.insert(
              id: id,
              shopId: shopId,
              customerId: (row['customer']! as Map<String, Object?>)['id']! as String,
              currency: row['currency']! as String,
              amount: Value(row['amount'] as int?),
              khrPerUsd: row['khrPerUsd']! as int,
              status: row['status']! as String,
              takenAt: _time(row['takenAt'])!,
              dueDate: Value(row['dueDate'] as String?),
              paidAt: Value(_time(row['paidAt'])),
              note: Value(row['note'] as String?),
              updatedAt: Value(at),
              updatedBy: Value(by),
              deletedAt: const Value(null),
              seq: Value(seq),
            ),
          );
      await _replaceLines(id, [
        for (final item in (row['items'] as List?) ?? const [])
          _serverLine(item! as Map<String, Object?>),
      ]);
    }
  }

  static CreditLine _serverLine(Map<String, Object?> l) => CreditLine(
    id: l['id']! as String,
    priceId: l['priceId'] as String?,
    name: l['name']! as String,
    unit: l['unit']! as String,
    qty: l['qty']! as int,
    currency: _currency(l['currency']! as String),
    unitPrice: l['unitPrice']! as int,
  );

  static DateTime? _time(Object? v) =>
      v == null ? null : DateTime.parse(v as String);

  static Currency _currency(String v) => Currency.values.byName(v.toLowerCase());

  static CreditCustomer _customer(CustomerRow r) =>
      CreditCustomer(id: r.id, name: r.name, phone: r.phone, note: r.note);

  static Credit _credit(CreditRow r, String customerName, List<CreditLine> lines) =>
      Credit(
        id: r.id,
        customerId: r.customerId,
        customerName: customerName,
        currency: _currency(r.currency),
        amount: r.amount,
        khrPerUsd: r.khrPerUsd,
        status: CreditStatus.values.byName(r.status),
        // Drift reads local time; the model always holds UTC.
        takenAt: r.takenAt.toUtc(),
        dueDate: r.dueDate,
        paidAt: r.paidAt?.toUtc(),
        note: r.note,
        lines: lines,
      );

  static CreditLine _line(CreditItemRow r) => CreditLine(
    id: r.id,
    priceId: r.priceId,
    name: r.name,
    unit: r.unit,
    qty: r.qty,
    currency: _currency(r.currency),
    unitPrice: r.unitPrice,
  );
}
