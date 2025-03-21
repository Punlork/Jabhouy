import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';
import 'package:my_app/app/app.dart';
import 'package:my_app/customer/customer.dart';

class LoanerModel extends Equatable {
  const LoanerModel({
    required this.id,
    required this.amount,
    required this.note,
    this.createdAt,
    this.customer,
    this.customerId,
    this.updatedAt,
  });

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

    if (updatedAt != null && createdAt != null && updatedAt!.isAfter(createdAt!)) {
      return dateFormat.format(updatedAt!);
    }
    return createdAt != null ? dateFormat.format(createdAt!) : 'N/A';
  }

  final int id;
  final int? customerId;
  final int amount;
  final String? note;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final CustomerModel? customer;

  Map<String, dynamic> toJson() => {
        'customerId': customerId,
        'amount': amount,
        'note': note,
      };

  @override
  List<Object?> get props => [id, amount, note, createdAt, updatedAt, customer, customerId];
}
