// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shop_item_model.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ShopItemModelCWProxy {
  ShopItemModel id(int id);

  ShopItemModel name(String name);

  ShopItemModel defaultPrice(int? defaultPrice);

  ShopItemModel customerPrice(int? customerPrice);

  ShopItemModel sellerPrice(int? sellerPrice);

  ShopItemModel note(String? note);

  ShopItemModel imageUrl(String? imageUrl);

  ShopItemModel category(CategoryItemModel? category);

  ShopItemModel createdAt(DateTime? createdAt);

  ShopItemModel updatedAt(DateTime? updatedAt);

  ShopItemModel syncStatus(SyncStatus syncStatus);

  ShopItemModel isDeleted(bool isDeleted);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ShopItemModel(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ShopItemModel(...).copyWith(id: 12, name: "My name")
  /// ```
  ShopItemModel call({
    int id,
    String name,
    int? defaultPrice,
    int? customerPrice,
    int? sellerPrice,
    String? note,
    String? imageUrl,
    CategoryItemModel? category,
    DateTime? createdAt,
    DateTime? updatedAt,
    SyncStatus syncStatus,
    bool isDeleted,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfShopItemModel.copyWith(...)` or call `instanceOfShopItemModel.copyWith.fieldName(value)` for a single field.
class _$ShopItemModelCWProxyImpl implements _$ShopItemModelCWProxy {
  const _$ShopItemModelCWProxyImpl(this._value);

  final ShopItemModel _value;

  @override
  ShopItemModel id(int id) => call(id: id);

  @override
  ShopItemModel name(String name) => call(name: name);

  @override
  ShopItemModel defaultPrice(int? defaultPrice) =>
      call(defaultPrice: defaultPrice);

  @override
  ShopItemModel customerPrice(int? customerPrice) =>
      call(customerPrice: customerPrice);

  @override
  ShopItemModel sellerPrice(int? sellerPrice) => call(sellerPrice: sellerPrice);

  @override
  ShopItemModel note(String? note) => call(note: note);

  @override
  ShopItemModel imageUrl(String? imageUrl) => call(imageUrl: imageUrl);

  @override
  ShopItemModel category(CategoryItemModel? category) =>
      call(category: category);

  @override
  ShopItemModel createdAt(DateTime? createdAt) => call(createdAt: createdAt);

  @override
  ShopItemModel updatedAt(DateTime? updatedAt) => call(updatedAt: updatedAt);

  @override
  ShopItemModel syncStatus(SyncStatus syncStatus) =>
      call(syncStatus: syncStatus);

  @override
  ShopItemModel isDeleted(bool isDeleted) => call(isDeleted: isDeleted);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ShopItemModel(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ShopItemModel(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ShopItemModel call({
    Object? id = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? defaultPrice = const $CopyWithPlaceholder(),
    Object? customerPrice = const $CopyWithPlaceholder(),
    Object? sellerPrice = const $CopyWithPlaceholder(),
    Object? note = const $CopyWithPlaceholder(),
    Object? imageUrl = const $CopyWithPlaceholder(),
    Object? category = const $CopyWithPlaceholder(),
    Object? createdAt = const $CopyWithPlaceholder(),
    Object? updatedAt = const $CopyWithPlaceholder(),
    Object? syncStatus = const $CopyWithPlaceholder(),
    Object? isDeleted = const $CopyWithPlaceholder(),
  }) {
    return ShopItemModel(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as int,
      name: name == const $CopyWithPlaceholder() || name == null
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      defaultPrice: defaultPrice == const $CopyWithPlaceholder()
          ? _value.defaultPrice
          // ignore: cast_nullable_to_non_nullable
          : defaultPrice as int?,
      customerPrice: customerPrice == const $CopyWithPlaceholder()
          ? _value.customerPrice
          // ignore: cast_nullable_to_non_nullable
          : customerPrice as int?,
      sellerPrice: sellerPrice == const $CopyWithPlaceholder()
          ? _value.sellerPrice
          // ignore: cast_nullable_to_non_nullable
          : sellerPrice as int?,
      note: note == const $CopyWithPlaceholder()
          ? _value.note
          // ignore: cast_nullable_to_non_nullable
          : note as String?,
      imageUrl: imageUrl == const $CopyWithPlaceholder()
          ? _value.imageUrl
          // ignore: cast_nullable_to_non_nullable
          : imageUrl as String?,
      category: category == const $CopyWithPlaceholder()
          ? _value.category
          // ignore: cast_nullable_to_non_nullable
          : category as CategoryItemModel?,
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

extension $ShopItemModelCopyWith on ShopItemModel {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfShopItemModel.copyWith(...)` or `instanceOfShopItemModel.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ShopItemModelCWProxy get copyWith => _$ShopItemModelCWProxyImpl(this);
}
