// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:equatable/equatable.dart';
import 'package:jabhouy/app/app.dart';
import 'package:jabhouy_core/jabhouy_core.dart';

class CategoryItemModel extends Equatable {
  const CategoryItemModel({
    required this.id,
    required this.name,
    this.syncStatus = SyncStatus.synced,
    this.isDeleted = false,
  });

  factory CategoryItemModel.fromJson(Map<String, dynamic> json) {
    return CategoryItemModel(
      id: tryCast<int>(json['id'], fallback: 0)!,
      name: tryCast<String>(json['name'], fallback: '')!,
      syncStatus:
            SyncStatus.fromWireValue(tryCast<int>(json['syncStatus']) ?? 0),
      isDeleted: tryCast<bool>(json['isDeleted']) ?? false,
    );
  }

  final int id;
  final String name;
  final SyncStatus syncStatus;
  final bool isDeleted;

  Map<String, dynamic> toJson() {
    return {'name': name};
  }

  CategoryItemModel copyWith({
    int? id,
    String? name,
    SyncStatus? syncStatus,
    bool? isDeleted,
  }) {
    return CategoryItemModel(
      id: id ?? this.id,
      name: name ?? this.name,
      syncStatus: syncStatus ?? this.syncStatus,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  @override
  List<Object?> get props => [id, name, syncStatus, isDeleted];
}
