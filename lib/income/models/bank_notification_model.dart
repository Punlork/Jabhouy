import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';
import 'package:my_app/app/app.dart';

enum BankApp {
  aba('aba', 'ABA Bank'),
  chipMong('chip_mong', 'Chip Mong Bank'),
  acleda('acleda', 'ACLEDA Bank'),
  unknown('unknown', 'Unknown');

  const BankApp(this.key, this.label);

  final String key;
  final String label;

  static BankApp fromKey(String? key) {
    switch (key) {
      case 'aba':
        return BankApp.aba;
      case 'chip_mong':
        return BankApp.chipMong;
      case 'acleda':
        return BankApp.acleda;
      default:
        return BankApp.unknown;
    }
  }

  static BankApp fromPackageName(String? packageName) {
    switch (packageName) {
      case 'com.paygo24.ibank':
        return BankApp.aba;
      case 'com.chipmongbank.mobileappproduction':
        return BankApp.chipMong;
      case 'kh.com.acleda.acledamobile':
        return BankApp.acleda;
      default:
        return BankApp.unknown;
    }
  }
}

enum NotificationRecordFilter {
  all,
  income,
  expense;
}

class BankNotificationModel extends Equatable {
  BankNotificationModel({
    required this.fingerprint,
    required this.packageName,
    required this.bankApp,
    required this.message,
    required this.isIncome,
    required this.receivedAt,
    this.id = 0,
    this.title,
    this.rawPayload,
    this.amount,
    this.currency = 'USD',
    this.source = 'native',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory BankNotificationModel.fromNativeMap(Map<String, dynamic> json) {
    final receivedAtRaw =
        tryCast<int>(json['receivedAt']) ?? tryCast<int>(json['received_at']) ?? DateTime.now().millisecondsSinceEpoch;
    final packageName = tryCast<String>(json['packageName']) ?? tryCast<String>(json['package_name']) ?? '';
    final title = tryCast<String>(json['title']);
    final message = tryCast<String>(json['message']) ?? tryCast<String>(json['text']) ?? '';
    final bankApp = BankApp.fromKey(tryCast<String>(json['bankKey'])) == BankApp.unknown
        ? BankApp.fromPackageName(packageName)
        : BankApp.fromKey(tryCast<String>(json['bankKey']));

    return BankNotificationModel(
      fingerprint: tryCast<String>(json['fingerprint']) ??
          [
            packageName,
            title ?? '',
            message,
            receivedAtRaw.toString(),
          ].join('|'),
      packageName: packageName,
      bankApp: bankApp,
      title: title,
      message: message,
      rawPayload: tryCast<String>(json['rawPayload']) ?? tryCast<String>(json['raw_payload']),
      amount: _parseDouble(json['amount']),
      currency: tryCast<String>(json['currency'], fallback: 'USD')!,
      isIncome: tryCast<bool>(json['isIncome']) ?? tryCast<bool>(json['is_income']) ?? true,
      receivedAt: DateTime.fromMillisecondsSinceEpoch(receivedAtRaw).toLocal(),
      source: tryCast<String>(json['source'], fallback: 'native')!,
      createdAt: tryCast<int>(json['createdAt'])?.let(
            (value) => DateTime.fromMillisecondsSinceEpoch(value).toLocal(),
          ) ??
          tryCast<String>(json['createdAt'])?.let(DateTime.parse)?.toLocal(),
    );
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value.replaceAll(',', '').trim());
    }
    return null;
  }

  final int id;
  final String fingerprint;
  final String packageName;
  final BankApp bankApp;
  final String? title;
  final String message;
  final String? rawPayload;
  final double? amount;
  final String currency;
  final bool isIncome;
  final DateTime receivedAt;
  final String source;
  final DateTime createdAt;

  String get receivedDateLabel => DateFormat('dd MMM yyyy').format(receivedAt);
  String get receivedTimeLabel => DateFormat('hh:mm a').format(receivedAt);

  String get amountLabel {
    if (amount == null) return '--';
    final hasDecimals = amount!.truncateToDouble() != amount!;
    if (currency == 'KHR') {
      return NumberFormat.currency(
        symbol: 'KHR ',
        decimalDigits: 0,
      ).format(amount);
    }
    return NumberFormat.currency(
      symbol: r'$ ',
      decimalDigits: hasDecimals ? 2 : 0,
    ).format(amount);
  }

  @override
  List<Object?> get props => [
        id,
        fingerprint,
        packageName,
        bankApp,
        title,
        message,
        rawPayload,
        amount,
        currency,
        isIncome,
        receivedAt,
        source,
        createdAt,
      ];
}

class IncomeSummary extends Equatable {
  const IncomeSummary({
    required this.totalIncome,
    required this.totalExpense,
    required this.totalCount,
    required this.incomeByBank,
  });

  factory IncomeSummary.fromItems(List<BankNotificationModel> items) {
    var totalIncome = 0.0;
    var totalExpense = 0.0;
    final incomeByBank = <BankApp, double>{};

    for (final item in items) {
      final amount = item.amount ?? 0;
      if (item.isIncome) {
        totalIncome += amount;
        incomeByBank.update(
          item.bankApp,
          (value) => value + amount,
          ifAbsent: () => amount,
        );
      } else {
        totalExpense += amount;
      }
    }

    return IncomeSummary(
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      totalCount: items.length,
      incomeByBank: incomeByBank,
    );
  }

  static const empty = IncomeSummary(
    totalIncome: 0,
    totalExpense: 0,
    totalCount: 0,
    incomeByBank: {},
  );

  final double totalIncome;
  final double totalExpense;
  final int totalCount;
  final Map<BankApp, double> incomeByBank;

  @override
  List<Object?> get props => [
        totalIncome,
        totalExpense,
        totalCount,
        incomeByBank.entries.map((entry) => '${entry.key.key}:${entry.value}').toList(growable: false),
      ];
}
