import 'dart:convert';

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
    final normalized = key?.trim().toLowerCase().replaceAll(RegExp(r'[\s-]+'), '_');
    switch (normalized) {
      case 'aba':
      case 'aba_bank':
      case 'aba_bank_mobile':
        return BankApp.aba;
      case 'chip_mong':
      case 'chipmong':
      case 'chip_mong_bank':
        return BankApp.chipMong;
      case 'acleda':
      case 'acleda_bank':
        return BankApp.acleda;
      default:
        final raw = key?.toLowerCase() ?? '';
        if (raw.contains('aba')) return BankApp.aba;
        if (raw.contains('chip') && raw.contains('mong')) return BankApp.chipMong;
        if (raw.contains('acleda')) return BankApp.acleda;
        return BankApp.unknown;
    }
  }

  static BankApp fromPackageName(String? packageName) {
    switch (packageName) {
      case 'com.paygo24.ibank':
        return BankApp.aba;
      case 'com.chipmongbank.mobileappproduction':
        return BankApp.chipMong;
      case 'com.domain.acledabankqr':
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
    final message =
        tryCast<String>(json['message']) ?? tryCast<String>(json['text']) ?? tryCast<String>(json['body']) ?? '';
    final rawBankKey = tryCast<String>(json['bankKey']) ?? tryCast<String>(json['bank_key']);
    final packageBankApp = BankApp.fromPackageName(packageName);
    final payloadBankApp = BankApp.fromKey(rawBankKey);
    final inferredBankApp = _inferBankFromText(
      [
        title,
        message,
        tryCast<String>(json['body']),
      ].whereType<String>().join(' '),
    );
    final bankApp = packageBankApp != BankApp.unknown
        ? packageBankApp
        : payloadBankApp != BankApp.unknown
            ? payloadBankApp
            : inferredBankApp;
    final amount = _parseDouble(json['amount']) ?? _extractAmountFromText(message);
    final currency = tryCast<String>(json['currency']) ??
        _extractCurrencyFromText(message) ??
        tryCast<String>(json['currency'], fallback: 'USD')!;

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
      amount: amount,
      currency: currency,
      isIncome: tryCast<bool>(json['isIncome']) ?? tryCast<bool>(json['is_income']) ?? true,
      receivedAt: DateTime.fromMillisecondsSinceEpoch(receivedAtRaw).toLocal(),
      source: tryCast<String>(json['source'], fallback: 'native')!,
      createdAt: tryCast<int>(json['createdAt'])?.let(
            (value) => DateTime.fromMillisecondsSinceEpoch(value).toLocal(),
          ) ??
          tryCast<String>(json['createdAt'])?.let(DateTime.parse)?.toLocal(),
    );
  }

  static Map<String, dynamic> _parsePayloadMap(dynamic payload) {
    if (payload is Map<String, dynamic>) {
      return payload;
    }
    if (payload is Map) {
      return Map<String, dynamic>.from(payload);
    }
    if (payload is String && payload.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(payload);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
        if (decoded is Map) {
          return Map<String, dynamic>.from(decoded);
        }
      } catch (_) {
        return const <String, dynamic>{};
      }
    }
    return const <String, dynamic>{};
  }

  static Map<String, dynamic> fromJSON(
    Map<String, dynamic> entry,
  ) {
    final payloadMap = _parsePayloadMap(entry['payload']);
    final dataMap = _parsePayloadMap(entry['data']);
    final mergedMap = <String, dynamic>{
      ...payloadMap,
      ...dataMap,
    };

    final bankKey = mergedMap['bankKey'] ?? mergedMap['bank_key'] ?? entry['bankKey'] ?? entry['bank_key'];
    final amount = mergedMap['amount'] ?? entry['amount'];

    final currency = mergedMap['currency'] ?? entry['currency'];
    final isIncome = mergedMap['isIncome'] ?? mergedMap['is_income'] ?? entry['isIncome'] ?? entry['is_income'];
    final message = mergedMap['message'] ?? mergedMap['text'] ?? entry['message'] ?? entry['text'] ?? entry['body'];
    final title = mergedMap['title'] ?? entry['title'];
    final packageName =
        mergedMap['packageName'] ?? mergedMap['package_name'] ?? entry['packageName'] ?? entry['package_name'];

    final createdAtRaw = entry['createdAt'] ?? entry['created_at'];
    final receivedAtRaw = mergedMap['receivedAt'] ?? mergedMap['received_at'] ?? createdAtRaw;

    final normalized = <String, dynamic>{
      ...mergedMap,
      'id': entry['id'],
      if (packageName != null) 'packageName': packageName,
      if (bankKey != null) 'bankKey': bankKey,
      if (amount != null) 'amount': amount,
      if (currency != null) 'currency': currency,
      if (isIncome != null) 'isIncome': isIncome,
      if (message != null) 'message': message,
      if (title != null) 'title': title,
      if (entry['fingerprint'] != null) 'fingerprint': entry['fingerprint'],
      if (entry['source'] != null) 'source': entry['source'],
      if (entry['status'] != null) 'status': entry['status'],
      if (!mergedMap.containsKey('createdAt') && createdAtRaw != null) 'createdAt': createdAtRaw,
      if (!mergedMap.containsKey('receivedAt') && receivedAtRaw != null) 'receivedAt': receivedAtRaw,
    };

    normalized['source'] = (normalized['source']?.toString().isNotEmpty ?? false) ? normalized['source'] : 'remote';

    if (normalized['fingerprint'] == null || normalized['fingerprint'].toString().isEmpty) {
      normalized['fingerprint'] = [
        normalized['packageName'] ?? normalized['package_name'] ?? '',
        normalized['title'] ?? '',
        normalized['message'] ?? normalized['text'] ?? '',
        normalized['receivedAt'] ?? normalized['createdAt'] ?? DateTime.now().millisecondsSinceEpoch,
      ].join('|');
    }

    return normalized;
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is Map) {
      final decimal = value[r'$numberDecimal'] ?? value['numberDecimal'] ?? value['value'];
      return _parseDouble(decimal);
    }
    if (value is String) {
      final cleaned = value.replaceAll(',', '').trim();
      final direct = double.tryParse(cleaned);
      if (direct != null) {
        return direct;
      }
      final matched = RegExp(r'(-?\d+(?:\.\d+)?)').firstMatch(cleaned)?.group(1);
      if (matched != null) {
        return double.tryParse(matched);
      }
    }
    return null;
  }

  static double? _extractAmountFromText(String text) {
    final normalized = text.replaceAll(',', '');
    final match = RegExp(r'(?:USD|KHR|\$|៛)?\s*(-?\d+(?:\.\d+)?)', caseSensitive: false).firstMatch(normalized);
    if (match == null) return null;
    return double.tryParse(match.group(1)!);
  }

  static String? _extractCurrencyFromText(String text) {
    final upper = text.toUpperCase();
    if (upper.contains('KHR') || upper.contains('៛')) return 'KHR';
    if (upper.contains('USD') || upper.contains(r'$')) return 'USD';
    return null;
  }

  static BankApp _inferBankFromText(String text) {
    final normalized = text.toLowerCase();
    if (normalized.contains('aba')) return BankApp.aba;
    if (normalized.contains('chip') && normalized.contains('mong')) {
      return BankApp.chipMong;
    }
    if (normalized.contains('acleda')) return BankApp.acleda;
    return BankApp.unknown;
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
    return formatAmount(
      amount: amount!,
      currency: currency,
    );
  }

  static String formatAmount({
    required double amount,
    required String currency,
  }) {
    final hasDecimals = amount.truncateToDouble() != amount;
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
    required this.totalIncomeByCurrency,
    required this.totalExpenseByCurrency,
    required this.incomeByBankByCurrency,
  });

  factory IncomeSummary.fromItems(List<BankNotificationModel> items) {
    var totalIncome = 0.0;
    var totalExpense = 0.0;
    final incomeByBank = <BankApp, double>{};
    final totalIncomeByCurrency = <String, double>{};
    final totalExpenseByCurrency = <String, double>{};
    final incomeByBankByCurrency = <String, Map<BankApp, double>>{};

    for (final item in items) {
      final amount = item.amount ?? 0;
      final currency = item.currency;
      if (item.isIncome) {
        totalIncome += amount;
        incomeByBank.update(
          item.bankApp,
          (value) => value + amount,
          ifAbsent: () => amount,
        );
        totalIncomeByCurrency.update(
          currency,
          (value) => value + amount,
          ifAbsent: () => amount,
        );
        incomeByBankByCurrency.putIfAbsent(currency, () => <BankApp, double>{}).update(
              item.bankApp,
              (value) => value + amount,
              ifAbsent: () => amount,
            );
      } else {
        totalExpense += amount;
        totalExpenseByCurrency.update(
          currency,
          (value) => value + amount,
          ifAbsent: () => amount,
        );
      }
    }

    return IncomeSummary(
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      totalCount: items.length,
      incomeByBank: incomeByBank,
      totalIncomeByCurrency: totalIncomeByCurrency,
      totalExpenseByCurrency: totalExpenseByCurrency,
      incomeByBankByCurrency: incomeByBankByCurrency,
    );
  }

  static const empty = IncomeSummary(
    totalIncome: 0,
    totalExpense: 0,
    totalCount: 0,
    incomeByBank: {},
    totalIncomeByCurrency: {},
    totalExpenseByCurrency: {},
    incomeByBankByCurrency: {},
  );

  final double totalIncome;
  final double totalExpense;
  final int totalCount;
  final Map<BankApp, double> incomeByBank;
  final Map<String, double> totalIncomeByCurrency;
  final Map<String, double> totalExpenseByCurrency;
  final Map<String, Map<BankApp, double>> incomeByBankByCurrency;

  @override
  List<Object?> get props => [
        totalIncome,
        totalExpense,
        totalCount,
        incomeByBank.entries.map((entry) => '${entry.key.key}:${entry.value}').toList(growable: false),
        totalIncomeByCurrency.entries.map((entry) => '${entry.key}:${entry.value}').toList(growable: false),
        totalExpenseByCurrency.entries.map((entry) => '${entry.key}:${entry.value}').toList(growable: false),
        incomeByBankByCurrency.entries
            .map(
              (entry) =>
                  '${entry.key}:${entry.value.entries.map((value) => '${value.key.key}:${value.value}').join(',')}',
            )
            .toList(growable: false),
      ];
}
