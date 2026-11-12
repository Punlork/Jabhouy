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

  /// Reads what a user typed: `30,000` riel or `7.5` dollars. Null for
  /// empty or invalid text, so a missing price never becomes 0.
  static Money? tryParse(String text, Currency currency) {
    final clean = text.replaceAll(',', '').trim();
    final pattern = switch (currency) {
      Currency.khr => RegExp(r'^\d+$'),
      Currency.usd => RegExp(r'^\d+(\.\d{0,2})?$'),
    };
    if (!pattern.hasMatch(clean)) return null;
    return switch (currency) {
      Currency.khr => Money(int.parse(clean), currency),
      Currency.usd => Money(_parseCents(clean), currency),
    };
  }

  static int _parseCents(String clean) {
    final [whole, ...rest] = clean.split('.');
    final cents = rest.isEmpty ? '00' : rest.first.padRight(2, '0');
    return int.parse(whole) * 100 + int.parse(cents);
  }

  /// `30,000 ៛` or `$7.50`.
  String format() => switch (currency) {
        Currency.khr => '${formatNumber()} ៛',
        Currency.usd => '\$${formatNumber()}',
      };

  /// The number without its sign: `30,000` or `7.50`.
  String formatNumber() => switch (currency) {
        Currency.khr => _group(amount),
        Currency.usd =>
          '${_group(amount ~/ 100)}.${(amount % 100).toString().padLeft(2, '0')}',
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
