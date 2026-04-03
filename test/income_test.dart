import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/income/income.dart';

void main() {
  test('IncomeSummary groups income by bank and totals expenses', () {
    final items = [
      BankNotificationModel(
        fingerprint: '1',
        packageName: 'com.paygo24.ibank',
        bankApp: BankApp.aba,
        message: 'Received money',
        amount: 10,
        isIncome: true,
        receivedAt: DateTime(2026),
      ),
      BankNotificationModel(
        fingerprint: '2',
        packageName: 'com.chipmongbank.mobileappproduction',
        bankApp: BankApp.chipMong,
        message: 'Received money',
        amount: 25,
        isIncome: true,
        receivedAt: DateTime(2026),
      ),
      BankNotificationModel(
        fingerprint: '3',
        packageName: 'kh.com.acleda.acledamobile',
        bankApp: BankApp.acleda,
        message: 'Transfer out',
        amount: 5,
        isIncome: false,
        receivedAt: DateTime(2026),
      ),
    ];

    final summary = IncomeSummary.fromItems(items);

    expect(summary.totalIncome, 35);
    expect(summary.totalExpense, 5);
    expect(summary.totalCount, 3);
    expect(summary.incomeByBank[BankApp.aba], 10);
    expect(summary.incomeByBank[BankApp.chipMong], 25);
  });
}
