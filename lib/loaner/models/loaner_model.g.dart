// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'loaner_model.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$LoanerModelCWProxy {
  LoanerModel id(int id);

  LoanerModel amount(int amount);

  LoanerModel note(String? note);

  LoanerModel customer(CustomerModel? customer);

  LoanerModel customerId(int? customerId);

  LoanerModel updatedAt(DateTime? updatedAt);

  LoanerModel isPaid(bool isPaid);

  LoanerModel createdAt(DateTime? createdAt);

  LoanerModel syncStatus(SyncStatus syncStatus);

  LoanerModel isDeleted(bool isDeleted);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `LoanerModel(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// LoanerModel(...).copyWith(id: 12, name: "My name")
  /// ```
  LoanerModel call({
    int id,
    int amount,
    String? note,
    CustomerModel? customer,
    int? customerId,
    DateTime? updatedAt,
    bool isPaid,
    DateTime? createdAt,
    SyncStatus syncStatus,
    bool isDeleted,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfLoanerModel.copyWith(...)` or call `instanceOfLoanerModel.copyWith.fieldName(value)` for a single field.
class _$LoanerModelCWProxyImpl implements _$LoanerModelCWProxy {
  const _$LoanerModelCWProxyImpl(this._value);

  final LoanerModel _value;

  @override
  LoanerModel id(int id) => call(id: id);

  @override
  LoanerModel amount(int amount) => call(amount: amount);

  @override
  LoanerModel note(String? note) => call(note: note);

  @override
  LoanerModel customer(CustomerModel? customer) => call(customer: customer);

  @override
  LoanerModel customerId(int? customerId) => call(customerId: customerId);

  @override
  LoanerModel updatedAt(DateTime? updatedAt) => call(updatedAt: updatedAt);

  @override
  LoanerModel isPaid(bool isPaid) => call(isPaid: isPaid);

  @override
  LoanerModel createdAt(DateTime? createdAt) => call(createdAt: createdAt);

  @override
  LoanerModel syncStatus(SyncStatus syncStatus) => call(syncStatus: syncStatus);

  @override
  LoanerModel isDeleted(bool isDeleted) => call(isDeleted: isDeleted);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `LoanerModel(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// LoanerModel(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  LoanerModel call({
    Object? id = const $CopyWithPlaceholder(),
    Object? amount = const $CopyWithPlaceholder(),
    Object? note = const $CopyWithPlaceholder(),
    Object? customer = const $CopyWithPlaceholder(),
    Object? customerId = const $CopyWithPlaceholder(),
    Object? updatedAt = const $CopyWithPlaceholder(),
    Object? isPaid = const $CopyWithPlaceholder(),
    Object? createdAt = const $CopyWithPlaceholder(),
    Object? syncStatus = const $CopyWithPlaceholder(),
    Object? isDeleted = const $CopyWithPlaceholder(),
  }) {
    return LoanerModel(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as int,
      amount: amount == const $CopyWithPlaceholder() || amount == null
          ? _value.amount
          // ignore: cast_nullable_to_non_nullable
          : amount as int,
      note: note == const $CopyWithPlaceholder()
          ? _value.note
          // ignore: cast_nullable_to_non_nullable
          : note as String?,
      customer: customer == const $CopyWithPlaceholder()
          ? _value.customer
          // ignore: cast_nullable_to_non_nullable
          : customer as CustomerModel?,
      customerId: customerId == const $CopyWithPlaceholder()
          ? _value.customerId
          // ignore: cast_nullable_to_non_nullable
          : customerId as int?,
      updatedAt: updatedAt == const $CopyWithPlaceholder()
          ? _value.updatedAt
          // ignore: cast_nullable_to_non_nullable
          : updatedAt as DateTime?,
      isPaid: isPaid == const $CopyWithPlaceholder() || isPaid == null
          ? _value.isPaid
          // ignore: cast_nullable_to_non_nullable
          : isPaid as bool,
      createdAt: createdAt == const $CopyWithPlaceholder()
          ? _value.createdAt
          // ignore: cast_nullable_to_non_nullable
          : createdAt as DateTime?,
      syncStatus:
          syncStatus == const $CopyWithPlaceholder() || syncStatus == null
          ? _value.syncStatus
          // ignore: cast_nullable_to_non_nullable
          : syncStatus as SyncStatus,
      isDeleted: isDeleted == const $CopyWithPlaceholder() || isDeleted == null
          ? _value.isDeleted
          // ignore: cast_nullable_to_non_nullable
          : isDeleted as bool,
    );
  }
}

extension $LoanerModelCopyWith on LoanerModel {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfLoanerModel.copyWith(...)` or `instanceOfLoanerModel.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$LoanerModelCWProxy get copyWith => _$LoanerModelCWProxyImpl(this);
}
