// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'item_list_cubit.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ItemListStateCWProxy {
  ItemListState loading(bool loading);

  ItemListState items(List<Item> items);

  ItemListState nicknameMatches(Map<String, String> nicknameMatches);

  ItemListState recent(List<Item> recent);

  ItemListState categories(List<ItemCategory> categories);

  ItemListState missingCount(int missingCount);

  ItemListState query(String query);

  ItemListState categoryId(String? categoryId);

  ItemListState missingOnly(bool missingOnly);

  ItemListState grid(bool grid);

  ItemListState sort(ItemSort sort);

  ItemListState sortReversed(bool sortReversed);

  ItemListState canEdit(bool canEdit);

  ItemListState settings(PriceSettings settings);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ItemListState(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ItemListState(...).copyWith(id: 12, name: "My name")
  /// ```
  ItemListState call({
    bool loading,
    List<Item> items,
    Map<String, String> nicknameMatches,
    List<Item> recent,
    List<ItemCategory> categories,
    int missingCount,
    String query,
    String? categoryId,
    bool missingOnly,
    bool grid,
    ItemSort sort,
    bool sortReversed,
    bool canEdit,
    PriceSettings settings,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfItemListState.copyWith(...)` or call `instanceOfItemListState.copyWith.fieldName(value)` for a single field.
class _$ItemListStateCWProxyImpl implements _$ItemListStateCWProxy {
  const _$ItemListStateCWProxyImpl(this._value);

  final ItemListState _value;

  @override
  ItemListState loading(bool loading) => call(loading: loading);

  @override
  ItemListState items(List<Item> items) => call(items: items);

  @override
  ItemListState nicknameMatches(Map<String, String> nicknameMatches) =>
      call(nicknameMatches: nicknameMatches);

  @override
  ItemListState recent(List<Item> recent) => call(recent: recent);

  @override
  ItemListState categories(List<ItemCategory> categories) =>
      call(categories: categories);

  @override
  ItemListState missingCount(int missingCount) =>
      call(missingCount: missingCount);

  @override
  ItemListState query(String query) => call(query: query);

  @override
  ItemListState categoryId(String? categoryId) => call(categoryId: categoryId);

  @override
  ItemListState missingOnly(bool missingOnly) => call(missingOnly: missingOnly);

  @override
  ItemListState grid(bool grid) => call(grid: grid);

  @override
  ItemListState sort(ItemSort sort) => call(sort: sort);

  @override
  ItemListState sortReversed(bool sortReversed) =>
      call(sortReversed: sortReversed);

  @override
  ItemListState canEdit(bool canEdit) => call(canEdit: canEdit);

  @override
  ItemListState settings(PriceSettings settings) => call(settings: settings);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ItemListState(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ItemListState(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ItemListState call({
    Object? loading = const $CopyWithPlaceholder(),
    Object? items = const $CopyWithPlaceholder(),
    Object? nicknameMatches = const $CopyWithPlaceholder(),
    Object? recent = const $CopyWithPlaceholder(),
    Object? categories = const $CopyWithPlaceholder(),
    Object? missingCount = const $CopyWithPlaceholder(),
    Object? query = const $CopyWithPlaceholder(),
    Object? categoryId = const $CopyWithPlaceholder(),
    Object? missingOnly = const $CopyWithPlaceholder(),
    Object? grid = const $CopyWithPlaceholder(),
    Object? sort = const $CopyWithPlaceholder(),
    Object? sortReversed = const $CopyWithPlaceholder(),
    Object? canEdit = const $CopyWithPlaceholder(),
    Object? settings = const $CopyWithPlaceholder(),
  }) {
    return ItemListState(
      loading: loading == const $CopyWithPlaceholder() || loading == null
          ? _value.loading
          // ignore: cast_nullable_to_non_nullable
          : loading as bool,
      items: items == const $CopyWithPlaceholder() || items == null
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<Item>,
      nicknameMatches:
          nicknameMatches == const $CopyWithPlaceholder() ||
              nicknameMatches == null
          ? _value.nicknameMatches
          // ignore: cast_nullable_to_non_nullable
          : nicknameMatches as Map<String, String>,
      recent: recent == const $CopyWithPlaceholder() || recent == null
          ? _value.recent
          // ignore: cast_nullable_to_non_nullable
          : recent as List<Item>,
      categories:
          categories == const $CopyWithPlaceholder() || categories == null
          ? _value.categories
          // ignore: cast_nullable_to_non_nullable
          : categories as List<ItemCategory>,
      missingCount:
          missingCount == const $CopyWithPlaceholder() || missingCount == null
          ? _value.missingCount
          // ignore: cast_nullable_to_non_nullable
          : missingCount as int,
      query: query == const $CopyWithPlaceholder() || query == null
          ? _value.query
          // ignore: cast_nullable_to_non_nullable
          : query as String,
      categoryId: categoryId == const $CopyWithPlaceholder()
          ? _value.categoryId
          // ignore: cast_nullable_to_non_nullable
          : categoryId as String?,
      missingOnly:
          missingOnly == const $CopyWithPlaceholder() || missingOnly == null
          ? _value.missingOnly
          // ignore: cast_nullable_to_non_nullable
          : missingOnly as bool,
      grid: grid == const $CopyWithPlaceholder() || grid == null
          ? _value.grid
          // ignore: cast_nullable_to_non_nullable
          : grid as bool,
      sort: sort == const $CopyWithPlaceholder() || sort == null
          ? _value.sort
          // ignore: cast_nullable_to_non_nullable
          : sort as ItemSort,
      sortReversed:
          sortReversed == const $CopyWithPlaceholder() || sortReversed == null
          ? _value.sortReversed
          // ignore: cast_nullable_to_non_nullable
          : sortReversed as bool,
      canEdit: canEdit == const $CopyWithPlaceholder() || canEdit == null
          ? _value.canEdit
          // ignore: cast_nullable_to_non_nullable
          : canEdit as bool,
      settings: settings == const $CopyWithPlaceholder() || settings == null
          ? _value.settings
          // ignore: cast_nullable_to_non_nullable
          : settings as PriceSettings,
    );
  }
}

extension $ItemListStateCopyWith on ItemListState {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfItemListState.copyWith(...)` or `instanceOfItemListState.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ItemListStateCWProxy get copyWith => _$ItemListStateCWProxyImpl(this);
}
