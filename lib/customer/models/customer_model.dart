import 'package:equatable/equatable.dart';

import 'package:my_app/app/app.dart';

class CustomerModel extends Equatable {
  const CustomerModel({
    required this.id,
    required this.name,
    this.createdAt,
    this.updatedAt,
    this.syncStatus = 0,
    this.isDeleted = false,
  });
  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    try {
      return CustomerModel(
        id: tryCast<int>(json['id'])!,
        name: tryCast<String>(json['name'])!,
        createdAt: tryCast<String>(json['createdAt'])?.let(DateTime.parse),
        updatedAt: tryCast<String>(json['updatedAt'])?.let(DateTime.parse),
        syncStatus: tryCast<int>(json['syncStatus']) ?? 0,
        isDeleted: tryCast<bool>(json['isDeleted']) ?? false,
      );
    } catch (e) {
      throw Exception('Failed to parse CustomerModel: $e');
    }
  }

  final int id;
  final String name;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int syncStatus;
  final bool isDeleted;

  Map<String, dynamic> toJson() => {
        'name': name,
      };

  @override
  List<Object?> get props => [id, name, createdAt, updatedAt, syncStatus, isDeleted];

  CustomerModel copyWith({
    int? id,
    String? name,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? syncStatus,
    bool? isDeleted,
  }) {
    return CustomerModel(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}
