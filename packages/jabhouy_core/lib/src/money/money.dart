/// Money as whole numbers in the smallest unit: riel, or cents.
/// The same rules run on the server (jabhouy-api #10).
library;

import 'package:meta/meta.dart';

enum Currency { khr, usd }

@immutable
class Money {
  const Money(this.amount, this.currency) : assert(amount >= 0, 'amount');

  /// Whole riel for [Currency.khr], cents for [Currency.usd].
  final int amount;
  final Currency currency;

  /// Converts with [khrPerUsd] riel per dollar, rounding half up:
  /// riel to the nearest 100 (the smallest note in use), dollars to a cent.
  Money convertTo(Currency to, {required int khrPerUsd}) {
    if (to == currency) return this;
    return switch (to) {
      Currency.khr => Money(_halfUp(amount * khrPerUsd, 10000) * 100, to),
      Currency.usd => Money(_halfUp(amount * 100, khrPerUsd), to),
    };
  }

  /// `30,000 ៛` or `$7.50`.
  String format() => switch (currency) {
        Currency.khr => '${_group(amount)} ៛',
        Currency.usd =>
          '\$${_group(amount ~/ 100)}.${(amount % 100).toString().padLeft(2, '0')}',
      };

  /// A converted value: `≈ $7.50`.
  String formatApprox() => '≈ ${format()}';

  static int _halfUp(int n, int d) => (2 * n + d) ~/ (2 * d);

  static String _group(int n) => n.toString().replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'),
        (_) => ',',
      );

  @override
  bool operator ==(Object other) =>
      other is Money && other.amount == amount && other.currency == currency;

  @override
  int get hashCode => Object.hash(amount, currency);

  @override
  String toString() => 'Money($amount, ${currency.name})';
}
