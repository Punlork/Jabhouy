import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:equatable/equatable.dart';

import 'package:jabhouy_core/jabhouy_core.dart';

part 'customer_model.g.dart';

@CopyWith()
class CustomerModel extends Equatable {
  const CustomerModel({
    required this.id,
    required this.name,
    this.createdAt,
    this.updatedAt,
    this.syncStatus = SyncStatus.synced,
    this.isDeleted = false,
  });
  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    try {
      return CustomerModel(
        id: tryCast<int>(json['id'])!,
        name: tryCast<String>(json['name'])!,
        createdAt: tryCast<String>(json['createdAt'])?.let(DateTime.parse),
        updatedAt: tryCast<String>(json['updatedAt'])?.let(DateTime.parse),
        syncStatus:
            SyncStatus.fromWireValue(tryCast<int>(json['syncStatus']) ?? 0),
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
  final SyncStatus syncStatus;
  final bool isDeleted;

  Map<String, dynamic> toJson() => {
        'name': name,
      };

  @override
  List<Object?> get props => [id, name, createdAt, updatedAt, syncStatus, isDeleted];

}
