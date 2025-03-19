import 'package:equatable/equatable.dart';
import 'package:my_app/app/app.dart';

class LoanerModel extends Equatable {
  const LoanerModel({
    required this.id,
    required this.name,
    required this.amount,
    required this.note,
    this.createdAt,
    this.updatedAt,
  });

  factory LoanerModel.fromJson(Map<String, dynamic> json) {
    return LoanerModel(
      id: tryCast<int>(json['id'])!,
      name: tryCast<String>(json['name'])!,
      amount: tryCast<int>(json['amount'])!,
      note: tryCast<String>(json['note']),
      createdAt: tryCast<String>(json['createdAt'])?.let(DateTime.parse),
      updatedAt: tryCast<String>(json['updatedAt'])?.let(DateTime.parse),
    );
  }

  final int id;
  final String name;
  final int amount;
  final String? note;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Map<String, dynamic> toJson() => {
        'name': name,
        'amount': amount,
        'note': note,
      };

  @override
  List<Object?> get props => [id, name, amount, note, createdAt, updatedAt];
}
