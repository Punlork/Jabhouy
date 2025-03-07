import 'package:equatable/equatable.dart';
import 'package:my_app/app/app.dart';

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
  });

  factory ShopItemModel.fromJson(Map<String, dynamic> json) {
    return ShopItemModel(
      id: tryCast<int>(json['id'])!,
      name: tryCast<String>(json['name'])!,
      defaultPrice: tryCast<int>(json['basePrice'], fallback: 0),
      customerPrice: tryCast<int>(json['customerPrice']),
      sellerPrice: tryCast<int>(json['sellerPrice']),
      note: tryCast<String>(json['note']),
      imageUrl: tryCast<String>(json['imageUrl']),
      category: tryCast<String>(json['category']),
      createdAt: tryCast<String>(json['createdAt'])?.let(DateTime.parse),
      updatedAt: tryCast<String>(json['updatedAt'])?.let(DateTime.parse),
    );
  }

  final int id;
  final String name;
  final int? defaultPrice;
  final int? customerPrice;
  final int? sellerPrice;
  final String? note;
  final String? imageUrl;
  final String? category;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'basePrice': defaultPrice,
      'customerPrice': customerPrice,
      'sellerPrice': sellerPrice,
      'note': note,
      'imageUrl': imageUrl,
      // 'category': category,
      // 'createdAt': createdAt?.toIso8601String(),
      // 'updatedAt': updatedAt?.toIso8601String(),
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
      ];

  ShopItemModel copyWith({
    int? id,
    String? userId,
    String? name,
    int? defaultPrice,
    int? customerPrice,
    int? sellerPrice,
    String? note,
    String? imageUrl,
    String? category,
    DateTime? createdAt,
    DateTime? updatedAt,
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
    );
  }
}
