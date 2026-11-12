// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'credit_form_cubit.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CreditFormStateCWProxy {
  CreditFormState takenAt(DateTime takenAt);

  CreditFormState status(CreditFormStatus status);

  CreditFormState customer(CreditCustomer? customer);

  CreditFormState lines(List<CreditLine> lines);

  CreditFormState currency(Currency currency);

  CreditFormState amount(int? amount);

  CreditFormState khrPerUsd(int khrPerUsd);

  CreditFormState dueDate(DateTime? dueDate);

  CreditFormState creditStatus(CreditStatus creditStatus);

  CreditFormState customerMissing(bool customerMissing);

  CreditFormState error(String? error);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CreditFormState(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CreditFormState(...).copyWith(id: 12, name: "My name")
  /// ```
  CreditFormState call({
    DateTime takenAt,
    CreditFormStatus status,
    CreditCustomer? customer,
    List<CreditLine> lines,
    Currency currency,
    int? amount,
    int khrPerUsd,
    DateTime? dueDate,
    CreditStatus creditStatus,
    bool customerMissing,
    String? error,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfCreditFormState.copyWith(...)` or call `instanceOfCreditFormState.copyWith.fieldName(value)` for a single field.
class _$CreditFormStateCWProxyImpl implements _$CreditFormStateCWProxy {
  const _$CreditFormStateCWProxyImpl(this._value);

  final CreditFormState _value;

  @override
  CreditFormState takenAt(DateTime takenAt) => call(takenAt: takenAt);

  @override
  CreditFormState status(CreditFormStatus status) => call(status: status);

  @override
  CreditFormState customer(CreditCustomer? customer) =>
      call(customer: customer);

  @override
  CreditFormState lines(List<CreditLine> lines) => call(lines: lines);

  @override
  CreditFormState currency(Currency currency) => call(currency: currency);

  @override
  CreditFormState amount(int? amount) => call(amount: amount);

  @override
  CreditFormState khrPerUsd(int khrPerUsd) => call(khrPerUsd: khrPerUsd);

  @override
  CreditFormState dueDate(DateTime? dueDate) => call(dueDate: dueDate);

  @override
  CreditFormState creditStatus(CreditStatus creditStatus) =>
      call(creditStatus: creditStatus);

  @override
  CreditFormState customerMissing(bool customerMissing) =>
      call(customerMissing: customerMissing);

  @override
  CreditFormState error(String? error) => call(error: error);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CreditFormState(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CreditFormState(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  CreditFormState call({
    Object? takenAt = const $CopyWithPlaceholder(),
    Object? status = const $CopyWithPlaceholder(),
    Object? customer = const $CopyWithPlaceholder(),
    Object? lines = const $CopyWithPlaceholder(),
    Object? currency = const $CopyWithPlaceholder(),
    Object? amount = const $CopyWithPlaceholder(),
    Object? khrPerUsd = const $CopyWithPlaceholder(),
    Object? dueDate = const $CopyWithPlaceholder(),
    Object? creditStatus = const $CopyWithPlaceholder(),
    Object? customerMissing = const $CopyWithPlaceholder(),
    Object? error = const $CopyWithPlaceholder(),
  }) {
    return CreditFormState(
      takenAt: takenAt == const $CopyWithPlaceholder() || takenAt == null
          ? _value.takenAt
          // ignore: cast_nullable_to_non_nullable
          : takenAt as DateTime,
      status: status == const $CopyWithPlaceholder() || status == null
          ? _value.status
          // ignore: cast_nullable_to_non_nullable
          : status as CreditFormStatus,
      customer: customer == const $CopyWithPlaceholder()
          ? _value.customer
          // ignore: cast_nullable_to_non_nullable
          : customer as CreditCustomer?,
      lines: lines == const $CopyWithPlaceholder() || lines == null
          ? _value.lines
          // ignore: cast_nullable_to_non_nullable
          : lines as List<CreditLine>,
      currency: currency == const $CopyWithPlaceholder() || currency == null
          ? _value.currency
          // ignore: cast_nullable_to_non_nullable
          : currency as Currency,
      amount: amount == const $CopyWithPlaceholder()
          ? _value.amount
          // ignore: cast_nullable_to_non_nullable
          : amount as int?,
      khrPerUsd: khrPerUsd == const $CopyWithPlaceholder() || khrPerUsd == null
          ? _value.khrPerUsd
          // ignore: cast_nullable_to_non_nullable
          : khrPerUsd as int,
      dueDate: dueDate == const $CopyWithPlaceholder()
          ? _value.dueDate
          // ignore: cast_nullable_to_non_nullable
          : dueDate as DateTime?,
      creditStatus:
          creditStatus == const $CopyWithPlaceholder() || creditStatus == null
          ? _value.creditStatus
          // ignore: cast_nullable_to_non_nullable
          : creditStatus as CreditStatus,
      customerMissing:
          customerMissing == const $CopyWithPlaceholder() ||
              customerMissing == null
          ? _value.customerMissing
          // ignore: cast_nullable_to_non_nullable
          : customerMissing as bool,
      error: error == const $CopyWithPlaceholder()
          ? _value.error
          // ignore: cast_nullable_to_non_nullable
          : error as String?,
    );
  }
}

extension $CreditFormStateCopyWith on CreditFormState {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfCreditFormState.copyWith(...)` or `instanceOfCreditFormState.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CreditFormStateCWProxy get copyWith => _$CreditFormStateCWProxyImpl(this);
}
