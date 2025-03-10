// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:my_app/app/app.dart';

class CategoryItemModel {
  CategoryItemModel({
    required this.id,
    required this.name,
    this.userId,
  });

  factory CategoryItemModel.fromJson(Map<String, dynamic> json) {
    return CategoryItemModel(
      id: tryCast<int>(json['id'], fallback: 0)!,
      name: tryCast<String>(json['name'], fallback: '')!,
      userId: tryCast<String>(json['userId']),
    );
  }

  final int id;
  final String name;
  final String? userId;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'userId': userId,
    };
  }

  CategoryItemModel copyWith({
    int? id,
    String? name,
    String? userId,
  }) {
    return CategoryItemModel(
      id: id ?? this.id,
      name: name ?? this.name,
      userId: userId ?? this.userId,
    );
  }
}
