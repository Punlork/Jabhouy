import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';
import 'package:my_app/app/app.dart';
import 'package:my_app/customer/customer.dart';

String _formatToRFC3339Date(DateTime date) {
  return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

class LoanerModel extends Equatable {
  LoanerModel({
    required this.id,
    required this.amount,
    this.note,
    this.customer,
    this.customerId,
    this.updatedAt,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory LoanerModel.fromJson(Map<String, dynamic> json) {
    return LoanerModel(
      id: tryCast<int>(json['id'])!,
      amount: tryCast<int>(json['amount'])!,
      note: tryCast<String>(json['note']),
      customer: tryCast<Map<String, dynamic>>(json['customer'])?.let(CustomerModel.fromJson),
      createdAt: tryCast<String>(json['createdAt'])?.let((s) => DateTime.parse(s).toLocal()),
      updatedAt: tryCast<String>(json['updatedAt'])?.let((s) => DateTime.parse(s).toLocal()),
    );
  }

  String get displayDate {
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

    if (updatedAt != null && updatedAt!.isAfter(createdAt)) {
      return dateFormat.format(updatedAt!);
    }

    return dateFormat.format(createdAt);
  }

  final int id;
  final int? customerId;
  final int amount;
  final String? note;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final CustomerModel? customer;

  Map<String, dynamic> toJson() => {
        'customerId': customerId,
        'amount': amount,
        'note': note,
        'createdAt': _formatToRFC3339Date(createdAt),
      };

  @override
  List<Object?> get props => [id, amount, note, createdAt, updatedAt, customer, customerId];
}
