// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'customer_model.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CustomerModelCWProxy {
  CustomerModel id(int id);

  CustomerModel name(String name);

  CustomerModel createdAt(DateTime? createdAt);

  CustomerModel updatedAt(DateTime? updatedAt);

  CustomerModel syncStatus(SyncStatus syncStatus);

  CustomerModel isDeleted(bool isDeleted);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CustomerModel(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CustomerModel(...).copyWith(id: 12, name: "My name")
  /// ```
  CustomerModel call({
    int id,
    String name,
    DateTime? createdAt,
    DateTime? updatedAt,
    SyncStatus syncStatus,
    bool isDeleted,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfCustomerModel.copyWith(...)` or call `instanceOfCustomerModel.copyWith.fieldName(value)` for a single field.
class _$CustomerModelCWProxyImpl implements _$CustomerModelCWProxy {
  const _$CustomerModelCWProxyImpl(this._value);

  final CustomerModel _value;

  @override
  CustomerModel id(int id) => call(id: id);

  @override
  CustomerModel name(String name) => call(name: name);

  @override
  CustomerModel createdAt(DateTime? createdAt) => call(createdAt: createdAt);

  @override
  CustomerModel updatedAt(DateTime? updatedAt) => call(updatedAt: updatedAt);

  @override
  CustomerModel syncStatus(SyncStatus syncStatus) =>
      call(syncStatus: syncStatus);

  @override
  CustomerModel isDeleted(bool isDeleted) => call(isDeleted: isDeleted);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CustomerModel(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CustomerModel(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  CustomerModel call({
    Object? id = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? createdAt = const $CopyWithPlaceholder(),
    Object? updatedAt = const $CopyWithPlaceholder(),
    Object? syncStatus = const $CopyWithPlaceholder(),
    Object? isDeleted = const $CopyWithPlaceholder(),
  }) {
    return CustomerModel(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as int,
      name: name == const $CopyWithPlaceholder() || name == null
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      createdAt: createdAt == const $CopyWithPlaceholder()
          ? _value.createdAt
          // ignore: cast_nullable_to_non_nullable
          : createdAt as DateTime?,
      updatedAt: updatedAt == const $CopyWithPlaceholder()
          ? _value.updatedAt
          // ignore: cast_nullable_to_non_nullable
          : updatedAt as DateTime?,
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

extension $CustomerModelCopyWith on CustomerModel {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfCustomerModel.copyWith(...)` or `instanceOfCustomerModel.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CustomerModelCWProxy get copyWith => _$CustomerModelCWProxyImpl(this);
}
