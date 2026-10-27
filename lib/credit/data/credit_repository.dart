import 'package:jabhouy/credit/data/credit_dao.dart';
import 'package:jabhouy/credit/logic/credit_money.dart';
import 'package:jabhouy/credit/models/credit.dart';
import 'package:jabhouy_core/jabhouy_core.dart';
import 'package:jabhouy_net/jabhouy_net.dart';
import 'package:jabhouy_shop/jabhouy_shop.dart' show normalizeSearch;
import 'package:jabhouy_sync/jabhouy_sync.dart';

const _viewerCannotDelete = AppException('Viewers cannot delete');
const _customerHasCredits = AppException('This customer has credits');

/// Credits and their Customers for the Current Shop. Writes go to Drift
/// first, then the outbox, then a sync is requested when online. The
/// stand-in Shop (`ShopScope.syncs` false) queues nothing.
///
/// Every Member adds, edits and marks Credits paid; only owner and editor
/// delete (decision 14).
class CreditRepository {
  CreditRepository(
    this._dao,
    this._scope,
    this._engine,
    this._connectivity, {
    this._clock = DateTime.now,
  });

  final CreditDao _dao;
  final ShopScope _scope;
  final SyncEngine _engine;
  final ConnectivityService _connectivity;
  final DateTime Function() _clock;

  /// False until the Current Shop is known (after sign-in).
  bool get ready => _scope.shopId != null;

  String get _shopId => _scope.shopId!;
  bool get _isViewer => _scope.role == MemberRole.viewer;

  /// Owner and editor delete; a viewer only records (decision 14).
  bool get canDelete => !_isViewer;

  /// Credits newest first; [search] narrows by customer name.
  Stream<List<Credit>> watchCredits({
    CreditFilter filter = CreditFilter.unpaid,
    String search = '',
  }) {
    final query = normalizeSearch(search);
    return _dao.watchCredits(_shopId).map((all) {
      return [
        for (final credit in all)
          if ((filter == CreditFilter.all ||
                  credit.isPaid == (filter == CreditFilter.paid)) &&
              (query.isEmpty ||
                  normalizeSearch(credit.customerName).contains(query)))
            credit,
      ];
    });
  }

  /// With its lines; null once deleted.
  Future<Credit?> credit(String id) => _dao.creditById(id);

  /// The shop's default currency and rate: a new Credit takes both, and
  /// keeps this rate for good.
  Future<({Currency currency, int khrPerUsd})> currentRates() =>
      _dao.rates(_shopId);

  Future<Result<Credit>> saveCredit(Credit credit) async {
    if (await _dao.customerById(credit.customerId) == null) {
      return const Err(AppException('Choose a customer'));
    }
    if (credit.lines.any((l) => l.qty < 1)) {
      return const Err(AppException('A line needs a quantity'));
    }
    final now = _clock();
    final sum = sumOfLines(credit.lines, credit.currency, credit.khrPerUsd);
    final saved = Credit(
      id: credit.id,
      customerId: credit.customerId,
      currency: credit.currency,
      // With lines the amount is their sum, never a typed value.
      amount: sum?.amount ?? credit.amount,
      khrPerUsd: credit.khrPerUsd,
      status: credit.status,
      takenAt: credit.takenAt,
      dueDate: credit.dueDate,
      paidAt: credit.isPaid ? credit.paidAt ?? now : null,
      note: credit.note,
      lines: credit.lines,
    );
    await _dao.saveCredit(_shopId, saved, now: now, userId: _scope.userId);
    await _queue(
      SyncEntityType.credit,
      saved.id,
      SyncOperation.update,
      now,
      dependsOn: saved.customerId,
    );
    return Ok(saved);
  }

  Future<Result<void>> markPaid(String id) async {
    final credit = await _dao.creditById(id);
    if (credit == null) return const Err(AppException('Credit not found'));
    if (credit.isPaid) return const Ok(null);
    final now = _clock();
    await saveCredit(
      credit.copyWith(status: CreditStatus.paid, paidAt: now),
    );
    return const Ok(null);
  }

  Future<Result<void>> deleteCredit(String id) async {
    if (_isViewer) return const Err(_viewerCannotDelete);
    final now = _clock();
    await _dao.markCreditDeleted(id, now, _scope.userId);
    await _queue(SyncEntityType.credit, id, SyncOperation.delete, now);
    return const Ok(null);
  }

  /// Customers A–Z with what each owes, in the shop's default currency
  /// (each Credit converted with its own rate); [search] narrows by name.
  Stream<List<CustomerBalance>> watchCustomers({String search = ''}) {
    final query = normalizeSearch(search);
    return _dao.watchCustomers(_shopId).asyncMap((rows) async {
      final currency = (await _dao.rates(_shopId)).currency;
      return [
        for (final row in rows)
          if (query.isEmpty ||
              normalizeSearch(row.customer.name).contains(query))
            _balance(row, currency),
      ];
    });
  }

  CustomerBalance _balance(CustomerRows row, Currency currency) {
    var owed = 0;
    var unknown = 0;
    for (final u in row.unpaid) {
      if (u.amount == null) {
        unknown++;
      } else {
        owed += Money(u.amount!, u.currency)
            .convertTo(currency, khrPerUsd: u.khrPerUsd)
            .amount;
      }
    }
    return CustomerBalance(
      customer: row.customer,
      owed: owed == 0 ? null : Money(owed, currency),
      unknownCount: unknown,
      creditCount: row.creditCount,
    );
  }

  /// Adds or renames. The only place a Customer is created is the picker.
  Future<Result<CreditCustomer>> saveCustomer(CreditCustomer customer) async {
    final name = customer.name.trim();
    if (name.isEmpty) return const Err(AppException('A customer needs a name'));
    final now = _clock();
    final saved = CreditCustomer(
      id: customer.id,
      name: name,
      phone: customer.phone,
      note: customer.note,
    );
    await _dao.saveCustomer(_shopId, saved, now: now, userId: _scope.userId);
    await _queue(
      SyncEntityType.creditCustomer,
      saved.id,
      SyncOperation.update,
      now,
    );
    return Ok(saved);
  }

  /// Refused while the Customer has any Credit, paid or not (decision 33).
  Future<Result<void>> deleteCustomer(String id) async {
    if (_isViewer) return const Err(_viewerCannotDelete);
    if (await _dao.creditCount(id) > 0) return const Err(_customerHasCredits);
    final now = _clock();
    await _dao.markCustomerDeleted(id, now, _scope.userId);
    await _queue(SyncEntityType.creditCustomer, id, SyncOperation.delete, now);
    return const Ok(null);
  }

  /// Pull to refresh: sends queued changes, then reads the Shop's
  /// `/changes` from where this phone left off.
  Future<void> pullLatest() async {
    if (!_scope.syncs || !await _connectivity.isOnline) return;
    await _engine.pullShop(_shopId);
  }

  Future<void> _queue(
    SyncEntityType type,
    String id,
    SyncOperation operation,
    DateTime now, {
    String? dependsOn,
  }) async {
    if (!_scope.syncs) return;
    await _engine.enqueue(
      entityType: type,
      localId: id,
      operation: operation,
      idempotencyKey: '${type.name}:$id:${now.microsecondsSinceEpoch}',
      dependsOnLocalId: dependsOn,
    );
    if (await _connectivity.isOnline) _engine.requestSync();
  }
}
