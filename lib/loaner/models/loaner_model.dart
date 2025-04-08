// ignore_for_file: public_member_api_docs, sort_constructors_first
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
    this.isPaid = false,
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
      isPaid: tryCast<bool>(json['paid'], fallback: false)!,
    );
  }

  String get displayDate {
    final dateFormat = DateFormat('dd MMM yyyy');
    return dateFormat.format(createdAt);
  }

  final int id;
  final int? customerId;
  final int amount;
  final String? note;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final CustomerModel? customer;
  final bool isPaid;

  Map<String, dynamic> toJson() => {
        'customerId': customerId,
        'amount': amount,
        'note': note,
        'createdAt': _formatToRFC3339Date(createdAt),
        'paid': isPaid,
      };

  @override
  List<Object?> get props => [id, amount, note, createdAt, updatedAt, customer, customerId];

  LoanerModel copyWith({
    int? id,
    int? customerId,
    int? amount,
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
    CustomerModel? customer,
    bool? isPaid,
  }) {
    return LoanerModel(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      amount: amount ?? this.amount,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      customer: customer ?? this.customer,
      isPaid: isPaid ?? this.isPaid,
    );
  }
}
