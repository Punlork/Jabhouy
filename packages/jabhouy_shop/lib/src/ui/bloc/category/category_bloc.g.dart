// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'category_bloc.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CategoryLoadedCWProxy {
  CategoryLoaded items(List<CategoryItemModel> items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CategoryLoaded(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CategoryLoaded(...).copyWith(id: 12, name: "My name")
  /// ```
  CategoryLoaded call({List<CategoryItemModel> items});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfCategoryLoaded.copyWith(...)` or call `instanceOfCategoryLoaded.copyWith.fieldName(value)` for a single field.
class _$CategoryLoadedCWProxyImpl implements _$CategoryLoadedCWProxy {
  const _$CategoryLoadedCWProxyImpl(this._value);

  final CategoryLoaded _value;

  @override
  CategoryLoaded items(List<CategoryItemModel> items) => call(items: items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CategoryLoaded(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CategoryLoaded(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  CategoryLoaded call({Object? items = const $CopyWithPlaceholder()}) {
    return CategoryLoaded(
      items: items == const $CopyWithPlaceholder() || items == null
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<CategoryItemModel>,
    );
  }
}

extension $CategoryLoadedCopyWith on CategoryLoaded {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfCategoryLoaded.copyWith(...)` or `instanceOfCategoryLoaded.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CategoryLoadedCWProxy get copyWith => _$CategoryLoadedCWProxyImpl(this);
}
