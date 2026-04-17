// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';

import 'package:my_app/app/app.dart';
import 'package:my_app/customer/customer.dart';

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
    this.syncStatus = 0,
    this.isDeleted = false,
  }) : createdAt = createdAt ?? DateTime.now();

  factory LoanerModel.fromJson(Map<String, dynamic> json) {
    return LoanerModel(
      id: tryCast<int>(json['id'])!,
      amount: tryCast<int>(json['amount'])!,
      note: tryCast<String>(json['note']),
      customerId: tryCast<int>(json['customerId']) ??
          tryCast<int>(json['customer_id']) ??
          tryCast<int>(json['customer']),
      customer: tryCast<Map<String, dynamic>>(json['customer'])
          ?.let(CustomerModel.fromJson),
      createdAt: tryCast<String>(json['createdAt'])
          ?.let((s) => DateTime.parse(s).toLocal()),
      updatedAt: tryCast<String>(json['updatedAt'])
          ?.let((s) => DateTime.parse(s).toLocal()),
      isPaid: tryCast<bool>(json['paid'], fallback: false)!,
      syncStatus: tryCast<int>(json['syncStatus']) ?? 0,
      isDeleted: tryCast<bool>(json['isDeleted']) ?? false,
    );
  }

  String get displayDate {
    final dateFormat = DateFormat('dd MMM yyyy');
    return dateFormat.format(createdAt);
  }

  String get displayDateTime {
    final dateTimeFormat = DateFormat('dd MMM yyyy, hh:mm a');
    return dateTimeFormat.format(createdAt);
  }

  final int id;
  final int? customerId;
  final int amount;
  final String? note;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final CustomerModel? customer;
  final bool isPaid;
  final int syncStatus;
  final bool isDeleted;

  Map<String, dynamic> toJson() => {
        'customerId': customerId,
        'amount': amount,
        'note': note,
        'createdAt': createdAt.toIso8601String(),
        'paid': isPaid,
      };

  @override
  List<Object?> get props => [
        id,
        amount,
        note,
        createdAt,
        updatedAt,
        customer,
        customerId,
        isPaid,
        syncStatus,
        isDeleted,
      ];

  LoanerModel copyWith({
    int? id,
    int? customerId,
    int? amount,
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
    CustomerModel? customer,
    bool? isPaid,
    int? syncStatus,
    bool? isDeleted,
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
      syncStatus: syncStatus ?? this.syncStatus,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}
