import 'package:equatable/equatable.dart';

class LoanerModel extends Equatable {
  const LoanerModel({
    required this.id,
    required this.name,
    required this.amount,
    required this.note,
  });

  factory LoanerModel.fromJson(Map<String, dynamic> json) => LoanerModel(
        id: json['id'] as String,
        name: json['name'] as String,
        amount: (json['amount'] as num).toDouble(),
        note: json['note'] as String? ?? '',
      );
  final String id;
  final String name;
  final double amount;
  final String note;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'amount': amount,
        'note': note,
      };

  @override
  List<Object> get props => [id, name, amount, note];
}
