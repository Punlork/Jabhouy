// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'customer_bloc.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CustomerLoadedCWProxy {
  CustomerLoaded customers(List<CustomerModel> customers);

  CustomerLoaded isOffline(bool isOffline);

  CustomerLoaded syncMessage(String? syncMessage);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CustomerLoaded(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CustomerLoaded(...).copyWith(id: 12, name: "My name")
  /// ```
  CustomerLoaded call({
    List<CustomerModel> customers,
    bool isOffline,
    String? syncMessage,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfCustomerLoaded.copyWith(...)` or call `instanceOfCustomerLoaded.copyWith.fieldName(value)` for a single field.
class _$CustomerLoadedCWProxyImpl implements _$CustomerLoadedCWProxy {
  const _$CustomerLoadedCWProxyImpl(this._value);

  final CustomerLoaded _value;

  @override
  CustomerLoaded customers(List<CustomerModel> customers) =>
      call(customers: customers);

  @override
  CustomerLoaded isOffline(bool isOffline) => call(isOffline: isOffline);

  @override
  CustomerLoaded syncMessage(String? syncMessage) =>
      call(syncMessage: syncMessage);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CustomerLoaded(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CustomerLoaded(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  CustomerLoaded call({
    Object? customers = const $CopyWithPlaceholder(),
    Object? isOffline = const $CopyWithPlaceholder(),
    Object? syncMessage = const $CopyWithPlaceholder(),
  }) {
    return CustomerLoaded(
      customers == const $CopyWithPlaceholder() || customers == null
          ? _value.customers
          // ignore: cast_nullable_to_non_nullable
          : customers as List<CustomerModel>,
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

extension $CustomerLoadedCopyWith on CustomerLoaded {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfCustomerLoaded.copyWith(...)` or `instanceOfCustomerLoaded.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CustomerLoadedCWProxy get copyWith => _$CustomerLoadedCWProxyImpl(this);
}
