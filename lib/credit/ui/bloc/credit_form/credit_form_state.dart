part of 'credit_form_cubit.dart';

enum CreditFormStatus { loading, ready, saved }

@CopyWith()
class CreditFormState extends Equatable {
  const CreditFormState({
    required this.takenAt,
    this.status = CreditFormStatus.loading,
    this.customer,
    this.lines = const [],
    this.currency = Currency.khr,
    this.amount,
    this.khrPerUsd = 4000,
    this.dueDate,
    this.creditStatus = CreditStatus.unpaid,
    this.customerMissing = false,
    this.error,
  });

  final CreditFormStatus status;
  final CreditCustomer? customer;
  final List<CreditLine> lines;

  /// The one currency the Credit is counted in.
  final Currency currency;

  /// Typed, in [currency]; null with [lines] (their sum stands) or while
  /// still empty.
  final int? amount;

  /// The rate kept on the Credit: the shop's when new, never changed on
  /// edit.
  final int khrPerUsd;

  /// A full moment, UTC.
  final DateTime takenAt;

  /// The local day it is due, if any.
  final DateTime? dueDate;
  final CreditStatus creditStatus;

  /// Saving was tried without a customer.
  final bool customerMissing;

  /// The repository's message when saving failed.
  final String? error;

  /// What the Credit comes to now: the lines' sum, else the typed amount.
  Money? get total =>
      sumOfLines(lines, currency, khrPerUsd) ??
      (amount == null ? null : Money(amount!, currency));

  @override
  List<Object?> get props => [
    status,
    customer?.id,
    customer?.name,
    [for (final l in lines) (l.id, l.qty, l.unitPrice)],
    currency,
    amount,
    khrPerUsd,
    takenAt,
    dueDate,
    creditStatus,
    customerMissing,
    error,
  ];
}
