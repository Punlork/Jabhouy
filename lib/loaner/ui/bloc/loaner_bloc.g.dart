// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'loaner_bloc.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$LoanerLoadedCWProxy {
  LoanerLoaded response(PaginatedResponse<LoanerModel> response);

  LoanerLoaded searchQuery(String searchQuery);

  LoanerLoaded fromDate(DateTime? fromDate);

  LoanerLoaded toDate(DateTime? toDate);

  LoanerLoaded loanerFilter(CustomerModel? loanerFilter);

  LoanerLoaded isOffline(bool isOffline);

  LoanerLoaded syncMessage(String? syncMessage);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `LoanerLoaded(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// LoanerLoaded(...).copyWith(id: 12, name: "My name")
  /// ```
  LoanerLoaded call({
    PaginatedResponse<LoanerModel> response,
    String searchQuery,
    DateTime? fromDate,
    DateTime? toDate,
    CustomerModel? loanerFilter,
    bool isOffline,
    String? syncMessage,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfLoanerLoaded.copyWith(...)` or call `instanceOfLoanerLoaded.copyWith.fieldName(value)` for a single field.
class _$LoanerLoadedCWProxyImpl implements _$LoanerLoadedCWProxy {
  const _$LoanerLoadedCWProxyImpl(this._value);

  final LoanerLoaded _value;

  @override
  LoanerLoaded response(PaginatedResponse<LoanerModel> response) =>
      call(response: response);

  @override
  LoanerLoaded searchQuery(String searchQuery) =>
      call(searchQuery: searchQuery);

  @override
  LoanerLoaded fromDate(DateTime? fromDate) => call(fromDate: fromDate);

  @override
  LoanerLoaded toDate(DateTime? toDate) => call(toDate: toDate);

  @override
  LoanerLoaded loanerFilter(CustomerModel? loanerFilter) =>
      call(loanerFilter: loanerFilter);

  @override
  LoanerLoaded isOffline(bool isOffline) => call(isOffline: isOffline);

  @override
  LoanerLoaded syncMessage(String? syncMessage) =>
      call(syncMessage: syncMessage);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `LoanerLoaded(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// LoanerLoaded(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  LoanerLoaded call({
    Object? response = const $CopyWithPlaceholder(),
    Object? searchQuery = const $CopyWithPlaceholder(),
    Object? fromDate = const $CopyWithPlaceholder(),
    Object? toDate = const $CopyWithPlaceholder(),
    Object? loanerFilter = const $CopyWithPlaceholder(),
    Object? isOffline = const $CopyWithPlaceholder(),
    Object? syncMessage = const $CopyWithPlaceholder(),
  }) {
    return LoanerLoaded(
      response == const $CopyWithPlaceholder() || response == null
          ? _value.response
          // ignore: cast_nullable_to_non_nullable
          : response as PaginatedResponse<LoanerModel>,
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
      loanerFilter: loanerFilter == const $CopyWithPlaceholder()
          ? _value.loanerFilter
          // ignore: cast_nullable_to_non_nullable
          : loanerFilter as CustomerModel?,
      isOffline: isOffline == const $CopyWithPlaceholder() || isOffline == null
          ? _value.isOffline
          // ignore: cast_nullable_to_non_nullable
          : isOffline as bool,
      syncMessage: syncMessage == const $CopyWithPlaceholder()
          ? _value.syncMessage
          // ignore: cast_nullable_to_non_nullable
          : syncMessage as String?,
    );
  }
}

extension $LoanerLoadedCopyWith on LoanerLoaded {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfLoanerLoaded.copyWith(...)` or `instanceOfLoanerLoaded.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$LoanerLoadedCWProxy get copyWith => _$LoanerLoadedCWProxyImpl(this);
}
