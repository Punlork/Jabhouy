// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:equatable/equatable.dart';
import 'package:my_app/app/app.dart';

class CategoryItemModel extends Equatable {
  const CategoryItemModel({
    required this.id,
    required this.name,
  });

  factory CategoryItemModel.fromJson(Map<String, dynamic> json) {
    return CategoryItemModel(
      id: tryCast<int>(json['id'], fallback: 0)!,
      name: tryCast<String>(json['name'], fallback: '')!,
    );
  }

  final int id;
  final String name;

  Map<String, dynamic> toJson() {
    return {'name': name};
  }

  CategoryItemModel copyWith({
    int? id,
    String? name,
    String? userId,
  }) {
    return CategoryItemModel(
      id: id ?? this.id,
      name: name ?? this.name,
    );
  }

  @override
  List<Object?> get props => [id, name];
}
