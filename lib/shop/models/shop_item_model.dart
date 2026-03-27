import 'package:equatable/equatable.dart';
import 'package:my_app/app/app.dart';
import 'package:my_app/shop/shop.dart';

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
    this.syncStatus = 0,
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
        json['category'] != null ? CategoryItemModel.fromJson(json['category'] as Map<String, dynamic>) : null,
      ),
      createdAt: tryCast<String>(json['createdAt'])?.let(DateTime.parse),
      updatedAt: tryCast<String>(json['updatedAt'])?.let(DateTime.parse),
      syncStatus: tryCast<int>(json['syncStatus']) ?? 0,
      isDeleted: tryCast<bool>(json['isDeleted']) ?? false,
    );
  }

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
  final int syncStatus;
  final bool isDeleted;

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

  ShopItemModel copyWith({
    int? id,
    String? name,
    int? defaultPrice,
    int? customerPrice,
    int? sellerPrice,
    String? note,
    String? imageUrl,
    CategoryItemModel? category,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? syncStatus,
    bool? isDeleted,
  }) {
    return ShopItemModel(
      id: id ?? this.id,
      name: name ?? this.name,
      defaultPrice: defaultPrice ?? this.defaultPrice,
      customerPrice: customerPrice ?? this.customerPrice,
      sellerPrice: sellerPrice ?? this.sellerPrice,
      note: note ?? this.note,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}
