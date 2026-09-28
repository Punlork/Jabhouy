// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shop_bloc.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ShopLoadedCWProxy {
  ShopLoaded paginatedItems(PaginatedResponse<ShopItemModel> paginatedItems);

  ShopLoaded searchQuery(String searchQuery);

  ShopLoaded categoryFilter(CategoryItemModel? categoryFilter);

  ShopLoaded isFiltering(bool? isFiltering);

  ShopLoaded isOffline(bool isOffline);

  ShopLoaded syncMessage(String? syncMessage);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ShopLoaded(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ShopLoaded(...).copyWith(id: 12, name: "My name")
  /// ```
  ShopLoaded call({
    PaginatedResponse<ShopItemModel> paginatedItems,
    String searchQuery,
    CategoryItemModel? categoryFilter,
    bool? isFiltering,
    bool isOffline,
    String? syncMessage,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfShopLoaded.copyWith(...)` or call `instanceOfShopLoaded.copyWith.fieldName(value)` for a single field.
class _$ShopLoadedCWProxyImpl implements _$ShopLoadedCWProxy {
  const _$ShopLoadedCWProxyImpl(this._value);

  final ShopLoaded _value;

  @override
  ShopLoaded paginatedItems(PaginatedResponse<ShopItemModel> paginatedItems) =>
      call(paginatedItems: paginatedItems);

  @override
  ShopLoaded searchQuery(String searchQuery) => call(searchQuery: searchQuery);

  @override
  ShopLoaded categoryFilter(CategoryItemModel? categoryFilter) =>
      call(categoryFilter: categoryFilter);

  @override
  ShopLoaded isFiltering(bool? isFiltering) => call(isFiltering: isFiltering);

  @override
  ShopLoaded isOffline(bool isOffline) => call(isOffline: isOffline);

  @override
  ShopLoaded syncMessage(String? syncMessage) => call(syncMessage: syncMessage);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ShopLoaded(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ShopLoaded(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ShopLoaded call({
    Object? paginatedItems = const $CopyWithPlaceholder(),
    Object? searchQuery = const $CopyWithPlaceholder(),
    Object? categoryFilter = const $CopyWithPlaceholder(),
    Object? isFiltering = const $CopyWithPlaceholder(),
    Object? isOffline = const $CopyWithPlaceholder(),
    Object? syncMessage = const $CopyWithPlaceholder(),
  }) {
    return ShopLoaded(
      paginatedItems:
          paginatedItems == const $CopyWithPlaceholder() ||
              paginatedItems == null
          ? _value.paginatedItems
          // ignore: cast_nullable_to_non_nullable
          : paginatedItems as PaginatedResponse<ShopItemModel>,
      searchQuery:
          searchQuery == const $CopyWithPlaceholder() || searchQuery == null
          ? _value.searchQuery
          // ignore: cast_nullable_to_non_nullable
          : searchQuery as String,
      categoryFilter: categoryFilter == const $CopyWithPlaceholder()
          ? _value.categoryFilter
          // ignore: cast_nullable_to_non_nullable
          : categoryFilter as CategoryItemModel?,
      isFiltering: isFiltering == const $CopyWithPlaceholder()
          ? _value.isFiltering
          // ignore: cast_nullable_to_non_nullable
          : isFiltering as bool?,
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

extension $ShopLoadedCopyWith on ShopLoaded {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfShopLoaded.copyWith(...)` or `instanceOfShopLoaded.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ShopLoadedCWProxy get copyWith => _$ShopLoadedCWProxyImpl(this);
}
