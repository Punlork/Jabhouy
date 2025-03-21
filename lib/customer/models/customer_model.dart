import 'package:equatable/equatable.dart';

import 'package:my_app/app/app.dart';

class CustomerModel extends Equatable {
  const CustomerModel({
    required this.id,
    required this.name,
    this.createdAt,
    this.updatedAt,
  });
  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    try {
      return CustomerModel(
        id: tryCast<int>(json['id'])!,
        name: tryCast<String>(json['name'])!,
        createdAt: tryCast<String>(json['createdAt'])?.let(DateTime.parse),
        updatedAt: tryCast<String>(json['updatedAt'])?.let(DateTime.parse),
      );
    } catch (e) {
      throw Exception('Failed to parse CustomerModel: $e');
    }
  }

  final int id;
  final String name;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Map<String, dynamic> toJson() => {
        'name': name,
      };

  @override
  List<Object?> get props => [id, name, createdAt, updatedAt];

  CustomerModel copyWith({
    int? id,
    String? name,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CustomerModel(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
