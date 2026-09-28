// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'income_bloc.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$IncomeLoadedCWProxy {
  IncomeLoaded items(List<BankNotificationModel> items);

  IncomeLoaded searchQuery(String searchQuery);

  IncomeLoaded fromDate(DateTime? fromDate);

  IncomeLoaded toDate(DateTime? toDate);

  IncomeLoaded bankFilter(BankApp? bankFilter);

  IncomeLoaded recordFilter(NotificationRecordFilter recordFilter);

  IncomeLoaded trackingStatus(NotificationTrackingStatus? trackingStatus);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `IncomeLoaded(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// IncomeLoaded(...).copyWith(id: 12, name: "My name")
  /// ```
  IncomeLoaded call({
    List<BankNotificationModel> items,
    String searchQuery,
    DateTime? fromDate,
    DateTime? toDate,
    BankApp? bankFilter,
    NotificationRecordFilter recordFilter,
    NotificationTrackingStatus? trackingStatus,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfIncomeLoaded.copyWith(...)` or call `instanceOfIncomeLoaded.copyWith.fieldName(value)` for a single field.
class _$IncomeLoadedCWProxyImpl implements _$IncomeLoadedCWProxy {
  const _$IncomeLoadedCWProxyImpl(this._value);

  final IncomeLoaded _value;

  @override
  IncomeLoaded items(List<BankNotificationModel> items) => call(items: items);

  @override
  IncomeLoaded searchQuery(String searchQuery) =>
      call(searchQuery: searchQuery);

  @override
  IncomeLoaded fromDate(DateTime? fromDate) => call(fromDate: fromDate);

  @override
  IncomeLoaded toDate(DateTime? toDate) => call(toDate: toDate);

  @override
  IncomeLoaded bankFilter(BankApp? bankFilter) => call(bankFilter: bankFilter);

  @override
  IncomeLoaded recordFilter(NotificationRecordFilter recordFilter) =>
      call(recordFilter: recordFilter);

  @override
  IncomeLoaded trackingStatus(NotificationTrackingStatus? trackingStatus) =>
      call(trackingStatus: trackingStatus);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `IncomeLoaded(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// IncomeLoaded(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  IncomeLoaded call({
    Object? items = const $CopyWithPlaceholder(),
    Object? searchQuery = const $CopyWithPlaceholder(),
    Object? fromDate = const $CopyWithPlaceholder(),
    Object? toDate = const $CopyWithPlaceholder(),
    Object? bankFilter = const $CopyWithPlaceholder(),
    Object? recordFilter = const $CopyWithPlaceholder(),
    Object? trackingStatus = const $CopyWithPlaceholder(),
  }) {
    return IncomeLoaded(
      items: items == const $CopyWithPlaceholder() || items == null
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<BankNotificationModel>,
      searchQuery:
          searchQuery == const $CopyWithPlaceholder() || searchQuery == null
          ? _value.searchQuery
          // ignore: cast_nullable_to_non_nullable
          : searchQuery as String,
      fromDate: fromDate == const $CopyWithPlaceholder()
          ? _value.fromDate
          // ignore: cast_nullable_to_non_nullable
          : fromDate as DateTime?,
      toDate: toDate == const $CopyWithPlaceholder()
          ? _value.toDate
          // ignore: cast_nullable_to_non_nullable
          : toDate as DateTime?,
      bankFilter: bankFilter == const $CopyWithPlaceholder()
          ? _value.bankFilter
          // ignore: cast_nullable_to_non_nullable
          : bankFilter as BankApp?,
      recordFilter:
          recordFilter == const $CopyWithPlaceholder() || recordFilter == null
          ? _value.recordFilter
          // ignore: cast_nullable_to_non_nullable
          : recordFilter as NotificationRecordFilter,
      trackingStatus: trackingStatus == const $CopyWithPlaceholder()
          ? _value.trackingStatus
          // ignore: cast_nullable_to_non_nullable
          : trackingStatus as NotificationTrackingStatus?,
    );
  }
}

extension $IncomeLoadedCopyWith on IncomeLoaded {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfIncomeLoaded.copyWith(...)` or `instanceOfIncomeLoaded.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$IncomeLoadedCWProxy get copyWith => _$IncomeLoadedCWProxyImpl(this);
}
