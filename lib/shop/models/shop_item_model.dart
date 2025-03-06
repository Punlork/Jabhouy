// ignore_for_file: avoid_dynamic_calls

import 'dart:developer';

import 'package:equatable/equatable.dart';

T? tryCast<T>(dynamic x, {T? fallback}) {
  if (x is T) return x;
  log('CastError when trying to cast $x to $T!');
  return fallback;
}

extension ObjectExtension<T> on T {
  R? let<R>(R Function(T) transform) => this != null ? transform(this!) : null;
}

class ShopItemModel extends Equatable {
  const ShopItemModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.defaultPrice,
    this.defaultBatchPrice,
    this.customerPrice,
    this.sellerPrice,
    this.customerBatchPrice,
    this.sellerBatchPrice,
    this.batchSize,
    this.note,
    this.imageUrl,
    this.category,
    this.createdAt,
    this.updatedAt,
  });

  factory ShopItemModel.fromJson(Map<String, dynamic> json) {
    return ShopItemModel(
      id: tryCast<int>(json['id'])!,
      userId: tryCast<String>(json['userId'])!,
      name: tryCast<String>(json['name'])!,
      defaultPrice: tryCast<num>(json['defaultPrice'], fallback: 0)!.toDouble(),
      defaultBatchPrice: tryCast<num>(json['defaultBatchPrice'])?.toDouble(),
      customerPrice: tryCast<num>(json['customerPrice'])?.toDouble(),
      sellerPrice: tryCast<num>(json['sellerPrice'])?.toDouble(),
      customerBatchPrice: tryCast<num>(json['customerBatchPrice'])?.toDouble(),
      sellerBatchPrice: tryCast<num>(json['sellerBatchPrice'])?.toDouble(),
      batchSize: tryCast<int>(json['batchSize']),
      note: tryCast<String>(json['note']),
      imageUrl: tryCast<String>(json['imageUrl']),
      category: tryCast<String>(json['category']),
      createdAt: tryCast<String>(json['createdAt'])?.let(DateTime.parse),
      updatedAt: tryCast<String>(json['updatedAt'])?.let(DateTime.parse),
    );
  }

  final int id;
  final String userId;
  final String name;
  final double defaultPrice;
  final double? defaultBatchPrice;
  final double? customerPrice;
  final double? sellerPrice;
  final double? customerBatchPrice;
  final double? sellerBatchPrice;
  final int? batchSize;
  final String? note;
  final String? imageUrl;
  final String? category;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isDistributorMode =>
      defaultBatchPrice != null &&
      customerPrice != null &&
      sellerBatchPrice != null &&
      customerBatchPrice != null &&
      sellerBatchPrice != null &&
      batchSize != null &&
      sellerPrice != null;

  Map<String, dynamic> toJson() {
    assert(
      name.isNotEmpty && defaultPrice > 0,
      'Name & Default price must be provided',
    );

    return {
      'userId': userId,
      'name': name,
      'defaultPrice': defaultPrice,
      'defaultBatchPrice': defaultBatchPrice,
      'customerPrice': customerPrice,
      'sellerPrice': sellerPrice,
      'customerBatchPrice': customerBatchPrice,
      'sellerBatchPrice': sellerBatchPrice,
      'batchSize': batchSize,
      'note': note,
      'imageUrl': imageUrl,
      'category': category,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        name,
        defaultPrice,
        defaultBatchPrice,
        customerPrice,
        sellerPrice,
        customerBatchPrice,
        sellerBatchPrice,
        batchSize,
        note,
        imageUrl,
        category,
        createdAt,
        updatedAt,
      ];
}
