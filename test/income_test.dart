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
        packageName: 'com.domain.acledabankqr',
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
    expect(summary.totalIncomeByCurrency['USD'], 35);
    expect(summary.totalExpenseByCurrency['USD'], 5);
  });

  test('BankNotificationModel prefers package bank over message mentions', () {
    final item = BankNotificationModel.fromNativeMap({
      'packageName': 'com.domain.acledabankqr',
      'bankKey': 'aba',
      'title': 'KHQR Payment ACLEDA mobile',
      'message': 'Received 1,000 KHR from PUNLORK CHEK, ABA Bank by KHQR.',
      'receivedAt': DateTime(2026).millisecondsSinceEpoch,
      'isIncome': true,
    });

    expect(item.bankApp, BankApp.acleda);
  });

  test('IncomeSummary separates income totals by currency', () {
    final items = [
      BankNotificationModel(
        fingerprint: '1',
        packageName: 'com.paygo24.ibank',
        bankApp: BankApp.aba,
        message: 'Received money',
        amount: 10,
        currency: 'USD',
        isIncome: true,
        receivedAt: DateTime(2026),
      ),
      BankNotificationModel(
        fingerprint: '2',
        packageName: 'com.domain.acledabankqr',
        bankApp: BankApp.acleda,
        message: 'Received money',
        amount: 40000,
        currency: 'KHR',
        isIncome: true,
        receivedAt: DateTime(2026),
      ),
    ];

    final summary = IncomeSummary.fromItems(items);

    expect(summary.totalIncomeByCurrency['USD'], 10);
    expect(summary.totalIncomeByCurrency['KHR'], 40000);
    expect(summary.incomeByBankByCurrency['USD']?[BankApp.aba], 10);
    expect(summary.incomeByBankByCurrency['KHR']?[BankApp.acleda], 40000);
  });
}
