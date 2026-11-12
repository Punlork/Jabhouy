// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'item_picker_cubit.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ItemPickerStateCWProxy {
  ItemPickerState loading(bool loading);

  ItemPickerState items(List<Item> items);

  ItemPickerState categories(List<ItemCategory> categories);

  ItemPickerState categoryId(String? categoryId);

  ItemPickerState query(String query);

  ItemPickerState quantities(Map<String, int> quantities);

  ItemPickerState lines(List<CreditLine> lines);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ItemPickerState(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ItemPickerState(...).copyWith(id: 12, name: "My name")
  /// ```
  ItemPickerState call({
    bool loading,
    List<Item> items,
    List<ItemCategory> categories,
    String? categoryId,
    String query,
    Map<String, int> quantities,
    List<CreditLine> lines,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfItemPickerState.copyWith(...)` or call `instanceOfItemPickerState.copyWith.fieldName(value)` for a single field.
class _$ItemPickerStateCWProxyImpl implements _$ItemPickerStateCWProxy {
  const _$ItemPickerStateCWProxyImpl(this._value);

  final ItemPickerState _value;

  @override
  ItemPickerState loading(bool loading) => call(loading: loading);

  @override
  ItemPickerState items(List<Item> items) => call(items: items);

  @override
  ItemPickerState categories(List<ItemCategory> categories) =>
      call(categories: categories);

  @override
  ItemPickerState categoryId(String? categoryId) =>
      call(categoryId: categoryId);

  @override
  ItemPickerState query(String query) => call(query: query);

  @override
  ItemPickerState quantities(Map<String, int> quantities) =>
      call(quantities: quantities);

  @override
  ItemPickerState lines(List<CreditLine> lines) => call(lines: lines);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ItemPickerState(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ItemPickerState(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ItemPickerState call({
    Object? loading = const $CopyWithPlaceholder(),
    Object? items = const $CopyWithPlaceholder(),
    Object? categories = const $CopyWithPlaceholder(),
    Object? categoryId = const $CopyWithPlaceholder(),
    Object? query = const $CopyWithPlaceholder(),
    Object? quantities = const $CopyWithPlaceholder(),
    Object? lines = const $CopyWithPlaceholder(),
  }) {
    return ItemPickerState(
      loading: loading == const $CopyWithPlaceholder() || loading == null
          ? _value.loading
          // ignore: cast_nullable_to_non_nullable
          : loading as bool,
      items: items == const $CopyWithPlaceholder() || items == null
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<Item>,
      categories:
          categories == const $CopyWithPlaceholder() || categories == null
          ? _value.categories
          // ignore: cast_nullable_to_non_nullable
          : categories as List<ItemCategory>,
      categoryId: categoryId == const $CopyWithPlaceholder()
          ? _value.categoryId
          // ignore: cast_nullable_to_non_nullable
          : categoryId as String?,
      query: query == const $CopyWithPlaceholder() || query == null
          ? _value.query
          // ignore: cast_nullable_to_non_nullable
          : query as String,
      quantities:
          quantities == const $CopyWithPlaceholder() || quantities == null
          ? _value.quantities
          // ignore: cast_nullable_to_non_nullable
          : quantities as Map<String, int>,
      lines: lines == const $CopyWithPlaceholder() || lines == null
          ? _value.lines
          // ignore: cast_nullable_to_non_nullable
          : lines as List<CreditLine>,
    );
  }
}

extension $ItemPickerStateCopyWith on ItemPickerState {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfItemPickerState.copyWith(...)` or `instanceOfItemPickerState.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ItemPickerStateCWProxy get copyWith => _$ItemPickerStateCWProxyImpl(this);
}
