// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'customer_picker_cubit.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CustomerPickerStateCWProxy {
  CustomerPickerState customers(List<CustomerBalance> customers);

  CustomerPickerState query(String query);

  CustomerPickerState loading(bool loading);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CustomerPickerState(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CustomerPickerState(...).copyWith(id: 12, name: "My name")
  /// ```
  CustomerPickerState call({
    List<CustomerBalance> customers,
    String query,
    bool loading,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfCustomerPickerState.copyWith(...)` or call `instanceOfCustomerPickerState.copyWith.fieldName(value)` for a single field.
class _$CustomerPickerStateCWProxyImpl implements _$CustomerPickerStateCWProxy {
  const _$CustomerPickerStateCWProxyImpl(this._value);

  final CustomerPickerState _value;

  @override
  CustomerPickerState customers(List<CustomerBalance> customers) =>
      call(customers: customers);

  @override
  CustomerPickerState query(String query) => call(query: query);

  @override
  CustomerPickerState loading(bool loading) => call(loading: loading);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CustomerPickerState(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CustomerPickerState(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  CustomerPickerState call({
    Object? customers = const $CopyWithPlaceholder(),
    Object? query = const $CopyWithPlaceholder(),
    Object? loading = const $CopyWithPlaceholder(),
  }) {
    return CustomerPickerState(
      customers: customers == const $CopyWithPlaceholder() || customers == null
          ? _value.customers
          // ignore: cast_nullable_to_non_nullable
          : customers as List<CustomerBalance>,
      query: query == const $CopyWithPlaceholder() || query == null
          ? _value.query
          // ignore: cast_nullable_to_non_nullable
          : query as String,
      loading: loading == const $CopyWithPlaceholder() || loading == null
          ? _value.loading
          // ignore: cast_nullable_to_non_nullable
          : loading as bool,
    );
  }
}

extension $CustomerPickerStateCopyWith on CustomerPickerState {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfCustomerPickerState.copyWith(...)` or `instanceOfCustomerPickerState.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CustomerPickerStateCWProxy get copyWith =>
      _$CustomerPickerStateCWProxyImpl(this);
}
