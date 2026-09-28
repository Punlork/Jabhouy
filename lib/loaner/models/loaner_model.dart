// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';

// The model file, not the barrel: the barrel exports customer's ui
// folder, which would put Flutter in the import closure of every
// file that touches a loan -- including logic/. Checked by
// test/architecture/logic_layer_test.dart.
import 'package:jabhouy/customer/models/customer_model.dart';
import 'package:jabhouy_core/jabhouy_core.dart';

part 'loaner_model.g.dart';

@CopyWith()
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
    this.syncStatus = SyncStatus.synced,
    this.isDeleted = false,
  }) : createdAt = createdAt ?? DateTime.now();

  factory LoanerModel.fromJson(Map<String, dynamic> json) {
    final customerJson = tryCast<Map<String, dynamic>>(json['customer']);
    return LoanerModel(
      id: tryCast<int>(json['id'])!,
      amount: tryCast<int>(json['amount'])!,
      note: tryCast<String>(json['note']),
      customerId: tryCast<int>(json['customerId']) ??
          tryCast<int>(json['customer_id']) ??
          tryCast<int>(json['customer']) ??
          // The loans API nests the customer and sends no flat id. Missing
          // this wrote null over every row a pull or push touched.
          tryCast<int>(customerJson?['id']),
      customer: customerJson?.let(CustomerModel.fromJson),
      createdAt: tryCast<String>(json['createdAt'])
          ?.let((s) => DateTime.parse(s).toLocal()),
      updatedAt: tryCast<String>(json['updatedAt'])
          ?.let((s) => DateTime.parse(s).toLocal()),
      isPaid: tryCast<bool>(json['paid'], fallback: false)!,
      syncStatus:
            SyncStatus.fromWireValue(tryCast<int>(json['syncStatus']) ?? 0),
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
  final SyncStatus syncStatus;
  final bool isDeleted;

  Map<String, dynamic> toJson() => {
        'customerId': customerId,
        'amount': amount,
        'note': note,
        // The server validates this as a date and stores midnight UTC, so
        // a timestamp is rejected with a 400 and the time is lost anyway.
        'createdAt': createdAt.toIsoDate(),
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

}
