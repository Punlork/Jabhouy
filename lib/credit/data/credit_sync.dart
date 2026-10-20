import 'package:jabhouy/credit/data/credit_dao.dart';
import 'package:jabhouy/credit/models/credit.dart';
import 'package:jabhouy_core/jabhouy_core.dart';
import 'package:jabhouy_sync/jabhouy_sync.dart';

/// Push and pull for Customers and Credits through a [ShopSyncApi], like
/// the shop's: adapters re-read the row on every attempt, appliers write
/// what `/changes` returns. Credit items travel inside their Credit and
/// replace the set (decision 27).

Map<String, Object?> _customerBody(CreditCustomer c) => {
  'id': c.id,
  'name': c.name,
  'phone': c.phone,
  'note': c.note,
};

String _iso(DateTime t) => t.toUtc().toIso8601String();

Map<String, Object?> _creditBody(Credit c) => {
  'id': c.id,
  'customer': {'id': c.customerId},
  'currency': c.currency.name.toUpperCase(),
  'amount': c.amount,
  'khrPerUsd': c.khrPerUsd,
  'status': c.status.name,
  'takenAt': _iso(c.takenAt),
  'dueDate': c.dueDate,
  'paidAt': c.paidAt == null ? null : _iso(c.paidAt!),
  'note': c.note,
  'items': [
    for (final l in c.lines)
      {
        'id': l.id,
        'priceId': l.priceId,
        'name': l.name,
        'unit': l.unit,
        'qty': l.qty,
        'currency': l.currency.name.toUpperCase(),
        'unitPrice': l.unitPrice,
        'total': l.total.amount,
      },
  ],
};

Future<SyncPushOutcome> _send(
  String shopId,
  Future<Result<void>> Function() call,
) async => switch (await call()) {
  Ok() => const SyncPushSucceeded(),
  Err(:final error) => outcomeForShopWrite(error, shopId),
};

/// `PUT` or `DELETE /shops/:id/customers/:custId`.
class CreditCustomerSyncAdapter implements FeatureSyncAdapter {
  const CreditCustomerSyncAdapter(this._dao, this._api, this._shopId);

  final CreditDao _dao;
  final ShopSyncApi _api;
  final String Function() _shopId;

  @override
  SyncEntityType get entityType => SyncEntityType.creditCustomer;

  @override
  Future<SyncPushOutcome> push(OutboxEntry entry) async {
    final shopId = _shopId();
    final customer = entry.operation == SyncOperation.delete
        ? null
        : await _dao.customerById(entry.localId);
    return _send(
      shopId,
      () => customer == null
          ? _api.delete(shopId, entityType, entry.localId)
          : _api.put(shopId, entityType, customer.id, _customerBody(customer)),
    );
  }
}

/// `PUT` or `DELETE /shops/:id/credits/:creditId`.
class CreditSyncAdapter implements FeatureSyncAdapter {
  const CreditSyncAdapter(this._dao, this._api, this._shopId);

  final CreditDao _dao;
  final ShopSyncApi _api;
  final String Function() _shopId;

  @override
  SyncEntityType get entityType => SyncEntityType.credit;

  @override
  Future<SyncPushOutcome> push(OutboxEntry entry) async {
    final shopId = _shopId();
    final credit = entry.operation == SyncOperation.delete
        ? null
        : await _dao.creditById(entry.localId);
    return _send(
      shopId,
      () => credit == null
          ? _api.delete(shopId, entityType, entry.localId)
          : _api.put(shopId, entityType, credit.id, _creditBody(credit)),
    );
  }
}

class CreditCustomerChangeApplier implements ChangeApplier {
  const CreditCustomerChangeApplier(this._dao);

  final CreditDao _dao;

  @override
  SyncEntityType get entityType => SyncEntityType.creditCustomer;

  @override
  Future<void> apply(
    String shopId,
    List<Map<String, Object?>> rows, {
    required Set<String> skipIds,
  }) => _dao.applyCustomers(shopId, rows, skipIds);
}

class CreditChangeApplier implements ChangeApplier {
  const CreditChangeApplier(this._dao);

  final CreditDao _dao;

  @override
  SyncEntityType get entityType => SyncEntityType.credit;

  @override
  Future<void> apply(
    String shopId,
    List<Map<String, Object?>> rows, {
    required Set<String> skipIds,
  }) => _dao.applyCredits(shopId, rows, skipIds);
}
