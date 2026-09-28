// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:equatable/equatable.dart';
import 'package:jabhouy_core/jabhouy_core.dart';

part 'category_model.g.dart';

@CopyWith()
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

  @override
  List<Object?> get props => [id, name, syncStatus, isDeleted];
}
