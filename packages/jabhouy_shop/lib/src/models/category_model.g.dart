// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'category_model.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CategoryItemModelCWProxy {
  CategoryItemModel id(int id);

  CategoryItemModel name(String name);

  CategoryItemModel syncStatus(SyncStatus syncStatus);

  CategoryItemModel isDeleted(bool isDeleted);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CategoryItemModel(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CategoryItemModel(...).copyWith(id: 12, name: "My name")
  /// ```
  CategoryItemModel call({
    int id,
    String name,
    SyncStatus syncStatus,
    bool isDeleted,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfCategoryItemModel.copyWith(...)` or call `instanceOfCategoryItemModel.copyWith.fieldName(value)` for a single field.
class _$CategoryItemModelCWProxyImpl implements _$CategoryItemModelCWProxy {
  const _$CategoryItemModelCWProxyImpl(this._value);

  final CategoryItemModel _value;

  @override
  CategoryItemModel id(int id) => call(id: id);

  @override
  CategoryItemModel name(String name) => call(name: name);

  @override
  CategoryItemModel syncStatus(SyncStatus syncStatus) =>
      call(syncStatus: syncStatus);

  @override
  CategoryItemModel isDeleted(bool isDeleted) => call(isDeleted: isDeleted);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CategoryItemModel(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CategoryItemModel(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  CategoryItemModel call({
    Object? id = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? syncStatus = const $CopyWithPlaceholder(),
    Object? isDeleted = const $CopyWithPlaceholder(),
  }) {
    return CategoryItemModel(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as int,
      name: name == const $CopyWithPlaceholder() || name == null
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
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

extension $CategoryItemModelCopyWith on CategoryItemModel {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfCategoryItemModel.copyWith(...)` or `instanceOfCategoryItemModel.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CategoryItemModelCWProxy get copyWith =>
      _$CategoryItemModelCWProxyImpl(this);
}
