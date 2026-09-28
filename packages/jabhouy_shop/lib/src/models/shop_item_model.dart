import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:equatable/equatable.dart';
import 'package:jabhouy_core/jabhouy_core.dart';
import 'package:jabhouy_shop/jabhouy_shop.dart';

part 'shop_item_model.g.dart';

@CopyWith()
class ShopItemModel extends Equatable {
  const ShopItemModel({
    required this.id,
    required this.name,
    this.defaultPrice,
    this.customerPrice,
    this.sellerPrice,
    this.note,
    this.imageUrl,
    this.category,
    this.createdAt,
    this.updatedAt,
    this.syncStatus = SyncStatus.synced,
    this.isDeleted = false,
  });

  factory ShopItemModel.fromJson(Map<String, dynamic> json) {
    return ShopItemModel(
      id: tryCast<int>(json['id'])!,
      name: tryCast<String>(json['name'])!,
      defaultPrice: tryCast<int>(json['basePrice']),
      customerPrice: tryCast<int>(json['customerPrice']),
      sellerPrice: tryCast<int>(json['sellerPrice']),
      note: tryCast<String>(json['note']),
      imageUrl: tryCast<String>(json['imageUrl']),
      category: tryCast<CategoryItemModel>(
        json['category'] != null
            ? CategoryItemModel.fromJson(
                json['category'] as Map<String, dynamic>,
              )
            : null,
      ),
      createdAt: tryCast<String>(json['createdAt'])?.let(DateTime.parse),
      updatedAt: tryCast<String>(json['updatedAt'])?.let(DateTime.parse),
      syncStatus:
            SyncStatus.fromWireValue(tryCast<int>(json['syncStatus']) ?? 0),
      isDeleted: tryCast<bool>(json['isDeleted']) ?? false,
    );
  }

  static final RegExp _packSuffixPattern = RegExp(r'\s*[x×]\s*(\d+)$');

  final int id;
  final String name;
  final int? defaultPrice;
  final int? customerPrice;
  final int? sellerPrice;
  final String? note;
  final String? imageUrl;
  final CategoryItemModel? category;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final SyncStatus syncStatus;
  final bool isDeleted;

  String get baseName =>
      name.trim().replaceFirst(_packSuffixPattern, '').trim();

  int? get packAmount {
    final match = _packSuffixPattern.firstMatch(name.trim());
    if (match == null) {
      return null;
    }
    return int.tryParse(match.group(1)!);
  }

  bool get isPack => (packAmount ?? 0) > 1;

  String get displayName => buildDisplayName(
        baseName,
        packAmount: packAmount,
      );

  static String buildDisplayName(
    String name, {
    int? packAmount,
  }) {
    final normalizedName =
        name.trim().replaceFirst(_packSuffixPattern, '').trim();
    if (normalizedName.isEmpty) {
      return normalizedName;
    }

    if (packAmount != null && packAmount > 1) {
      return '$normalizedName x$packAmount';
    }

    return normalizedName;
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'basePrice': defaultPrice,
      'customerPrice': customerPrice,
      'sellerPrice': sellerPrice,
      'note': note,
      'imageUrl': imageUrl,
      'categoryId': category?.id,
    };
  }

  @override
  List<Object?> get props => [
        id,
        name,
        defaultPrice,
        customerPrice,
        sellerPrice,
        note,
        imageUrl,
        category,
        createdAt,
        updatedAt,
        syncStatus,
        isDeleted,
      ];

}
