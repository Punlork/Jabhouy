import 'package:flutter_test/flutter_test.dart';
import 'package:jabhouy/credit/logic/credit_money.dart';
import 'package:jabhouy/credit/models/credit.dart';
import 'package:jabhouy_core/jabhouy_core.dart';

CreditLine _line(String name, int qty, int price, [Currency c = Currency.khr]) =>
    CreditLine(
      id: name,
      name: name,
      unit: 'ដប',
      qty: qty,
      currency: c,
      unitPrice: price,
    );

Credit _credit({
  String customer = 'u',
  List<CreditLine> lines = const [],
  int? amount,
  Currency currency = Currency.khr,
  int rate = 4000,
}) => Credit(
  id: 'c',
  customerId: customer,
  currency: currency,
  khrPerUsd: rate,
  takenAt: DateTime.utc(2026, 10, 20),
  amount: amount,
  lines: lines,
);

void main() {
  test(r'2 × 3,000 + 5 × 3,800 = 25,000 ៛, about $6.25', () {
    final credit = _credit(
      lines: [_line('ទឹក', 2, 3000), _line('អង្ករ', 5, 3800)],
    );

    expect(amountOf(credit), const Money(25000, Currency.khr));
    expect(
      const Money(25000, Currency.khr).convertTo(Currency.usd, khrPerUsd: 4000),
      const Money(625, Currency.usd),
    );
  });

  test('a USD line converts per line, rounded to 100 ៛', () {
    // $0.30 x 3 = $0.90 -> 3,600 ៛ at 4,000; $1.25 -> 5,000 ៛.
    final credit = _credit(
      lines: [_line('a', 3, 30, Currency.usd), _line('b', 1, 125, Currency.usd)],
    );

    expect(amountOf(credit), const Money(3600 + 5000, Currency.khr));
    // Rounding happens per line, not once on the sum.
    final line = _line('c', 1, 1, Currency.usd); // 1 cent = 40 ៛ -> 0
    expect(lineIn(line, Currency.khr, 4000), const Money(0, Currency.khr));
  });

  test('with no lines the typed amount stands; none is null', () {
    expect(amountOf(_credit(amount: 7000)), const Money(7000, Currency.khr));
    expect(amountOf(_credit()), isNull);
  });

  test('a Credit reads by its own rate snapshot, not the shop rate', () {
    final credit = _credit(amount: 400000);

    expect(amountIn(credit, Currency.usd), const Money(10000, Currency.usd));
    // The same Credit made at 4,100 reads differently, by its own rate only.
    final other = _credit(amount: 410000, rate: 4100);
    expect(amountIn(other, Currency.usd), const Money(10000, Currency.usd));
  });

  test('the summary converts each Credit with its own snapshot', () {
    final a = _credit(amount: 400000); // 4,000 rate -> $100.00
    final b = _credit(customer: 'v', amount: 410000, rate: 4100); // -> $100.00
    final unknown = _credit(customer: 'w');
    final again = _credit(customer: 'v', amount: 1000);

    final summary = summarize([a, b, unknown, again], Currency.khr);

    expect(summary.total, const Money(811000, Currency.khr));
    expect(summary.other, const Money(20025, Currency.usd));
    expect(summary.people, 3, reason: 'v counted once');
    expect(summary.peopleWithoutAmount, 1);
  });
}
