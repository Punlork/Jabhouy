import 'package:jabhouy_core/jabhouy_core.dart';

enum CreditStatus { unpaid, paid }

/// The list's chips: `មិនទាន់សង` (default), `សងរួច`, `ទាំងអស់`.
enum CreditFilter { unpaid, paid, all }

/// The list's order: `ក–អ` by customer, or newest first (default).
enum CreditSort { name, recent }

/// Someone who takes goods on credit. Created in the customer picker.
class CreditCustomer {
  const CreditCustomer({
    required this.id,
    required this.name,
    this.phone,
    this.note,
  });

  final String id;
  final String name;
  final String? phone;
  final String? note;
}

/// One thing taken on a Credit: a copy of its name, unit and price at
/// that time, so a later price change never alters an old debt.
class CreditLine {
  const CreditLine({
    required this.id,
    required this.name,
    required this.unit,
    required this.qty,
    required this.currency,
    required this.unitPrice,
    this.priceId,
  });

  final String id;

  /// The Price option it came from; null if that was deleted since.
  final String? priceId;
  final String name;
  final String unit;
  final int qty;

  /// The currency of [unitPrice], which may differ from the Credit's.
  final Currency currency;

  /// Whole riel or cents.
  final int unitPrice;

  /// In [currency], before any conversion.
  Money get total => Money(unitPrice * qty, currency);
}

/// A debt: what a Customer took and has not paid for.
class Credit {
  const Credit({
    required this.id,
    required this.customerId,
    required this.currency,
    required this.khrPerUsd,
    required this.takenAt,
    this.customerName = '',
    this.amount,
    this.status = CreditStatus.unpaid,
    this.dueDate,
    this.paidAt,
    this.note,
    this.lines = const [],
  });

  final String id;
  final String customerId;

  /// For rows; filled when read, ignored when saved.
  final String customerName;

  /// The one currency this Credit is counted in.
  final Currency currency;

  /// Whole riel or cents; null is "no amount yet". With [lines] it is
  /// their sum, set when saved.
  final int? amount;

  /// The shop's rate when this Credit was made. It never follows later
  /// changes (decision 32).
  final int khrPerUsd;
  final CreditStatus status;

  /// A full moment; stored in UTC, shown in UTC+7.
  final DateTime takenAt;

  /// `YYYY-MM-DD`, the local day.
  final String? dueDate;
  final DateTime? paidAt;
  final String? note;
  final List<CreditLine> lines;

  bool get isPaid => status == CreditStatus.paid;

  Credit copyWith({
    Currency? currency,
    int? amount,
    bool clearAmount = false,
    CreditStatus? status,
    DateTime? paidAt,
    bool clearPaidAt = false,
    List<CreditLine>? lines,
  }) => Credit(
    id: id,
    customerId: customerId,
    customerName: customerName,
    currency: currency ?? this.currency,
    amount: clearAmount ? null : amount ?? this.amount,
    khrPerUsd: khrPerUsd,
    status: status ?? this.status,
    takenAt: takenAt,
    dueDate: dueDate,
    paidAt: clearPaidAt ? null : paidAt ?? this.paidAt,
    note: note,
    lines: lines ?? this.lines,
  );
}

/// A Customer with what they currently owe, for the picker.
class CustomerBalance {
  const CustomerBalance({
    required this.customer,
    required this.owed,
    required this.unknownCount,
    required this.creditCount,
  });

  final CreditCustomer customer;

  /// Unpaid known amounts, in the shop's default currency; null when
  /// they owe nothing known.
  final Money? owed;

  /// Unpaid Credits with no amount yet.
  final int unknownCount;

  /// Every Credit they have, paid or not: any blocks deleting them.
  final int creditCount;
}
