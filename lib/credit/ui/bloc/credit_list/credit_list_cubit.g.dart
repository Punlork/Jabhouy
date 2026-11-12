// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'credit_list_cubit.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CreditListStateCWProxy {
  CreditListState loading(bool loading);

  CreditListState credits(List<Credit> credits);

  CreditListState summary(CreditSummary? summary);

  CreditListState filter(CreditFilter filter);

  CreditListState query(String query);

  CreditListState sort(CreditSort sort);

  CreditListState sortReversed(bool sortReversed);

  CreditListState currency(Currency currency);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CreditListState(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CreditListState(...).copyWith(id: 12, name: "My name")
  /// ```
  CreditListState call({
    bool loading,
    List<Credit> credits,
    CreditSummary? summary,
    CreditFilter filter,
    String query,
    CreditSort sort,
    bool sortReversed,
    Currency currency,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfCreditListState.copyWith(...)` or call `instanceOfCreditListState.copyWith.fieldName(value)` for a single field.
class _$CreditListStateCWProxyImpl implements _$CreditListStateCWProxy {
  const _$CreditListStateCWProxyImpl(this._value);

  final CreditListState _value;

  @override
  CreditListState loading(bool loading) => call(loading: loading);

  @override
  CreditListState credits(List<Credit> credits) => call(credits: credits);

  @override
  CreditListState summary(CreditSummary? summary) => call(summary: summary);

  @override
  CreditListState filter(CreditFilter filter) => call(filter: filter);

  @override
  CreditListState query(String query) => call(query: query);

  @override
  CreditListState sort(CreditSort sort) => call(sort: sort);

  @override
  CreditListState sortReversed(bool sortReversed) =>
      call(sortReversed: sortReversed);

  @override
  CreditListState currency(Currency currency) => call(currency: currency);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CreditListState(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CreditListState(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  CreditListState call({
    Object? loading = const $CopyWithPlaceholder(),
    Object? credits = const $CopyWithPlaceholder(),
    Object? summary = const $CopyWithPlaceholder(),
    Object? filter = const $CopyWithPlaceholder(),
    Object? query = const $CopyWithPlaceholder(),
    Object? sort = const $CopyWithPlaceholder(),
    Object? sortReversed = const $CopyWithPlaceholder(),
    Object? currency = const $CopyWithPlaceholder(),
  }) {
    return CreditListState(
      loading: loading == const $CopyWithPlaceholder() || loading == null
          ? _value.loading
          // ignore: cast_nullable_to_non_nullable
          : loading as bool,
      credits: credits == const $CopyWithPlaceholder() || credits == null
          ? _value.credits
          // ignore: cast_nullable_to_non_nullable
          : credits as List<Credit>,
      summary: summary == const $CopyWithPlaceholder()
          ? _value.summary
          // ignore: cast_nullable_to_non_nullable
          : summary as CreditSummary?,
      filter: filter == const $CopyWithPlaceholder() || filter == null
          ? _value.filter
          // ignore: cast_nullable_to_non_nullable
          : filter as CreditFilter,
      query: query == const $CopyWithPlaceholder() || query == null
          ? _value.query
          // ignore: cast_nullable_to_non_nullable
          : query as String,
      sort: sort == const $CopyWithPlaceholder() || sort == null
          ? _value.sort
          // ignore: cast_nullable_to_non_nullable
          : sort as CreditSort,
      sortReversed:
          sortReversed == const $CopyWithPlaceholder() || sortReversed == null
          ? _value.sortReversed
          // ignore: cast_nullable_to_non_nullable
          : sortReversed as bool,
      currency: currency == const $CopyWithPlaceholder() || currency == null
          ? _value.currency
          // ignore: cast_nullable_to_non_nullable
          : currency as Currency,
    );
  }
}

extension $CreditListStateCopyWith on CreditListState {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfCreditListState.copyWith(...)` or `instanceOfCreditListState.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CreditListStateCWProxy get copyWith => _$CreditListStateCWProxyImpl(this);
}
