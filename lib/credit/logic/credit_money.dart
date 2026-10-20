import 'package:jabhouy/credit/models/credit.dart';
import 'package:jabhouy_core/jabhouy_core.dart';

/// The Credit money rules (plan decisions 30 and 32). Pure, so the
/// server's copy (jabhouy-api #10) can be checked against the same cases.

/// What [line] adds to a Credit counted in [currency]: its total, converted
/// and rounded per line (100 ៛ or 1 cent) with the Credit's rate.
Money lineIn(CreditLine line, Currency currency, int khrPerUsd) =>
    line.total.convertTo(currency, khrPerUsd: khrPerUsd);

/// The sum of [lines] in [currency]; null with no lines (the amount is
/// then typed, or still unknown).
Money? sumOfLines(
  List<CreditLine> lines,
  Currency currency,
  int khrPerUsd,
) => lines.isEmpty
    ? null
    : Money(
        lines.fold(0, (sum, l) => sum + lineIn(l, currency, khrPerUsd).amount),
        currency,
      );

/// What [credit] is for: its lines' sum, else its typed amount, else null.
Money? amountOf(Credit credit) =>
    sumOfLines(credit.lines, credit.currency, credit.khrPerUsd) ??
    (credit.amount == null ? null : Money(credit.amount!, credit.currency));

/// [credit]'s amount in [currency] with its own rate snapshot, never the
/// shop's current one.
Money? amountIn(Credit credit, Currency currency) =>
    _of(credit.currency, credit.amount, credit.khrPerUsd, currency);

Money? _of(Currency from, int? amount, int khrPerUsd, Currency to) =>
    amount == null
    ? null
    : Money(amount, from).convertTo(to, khrPerUsd: khrPerUsd);

/// The list's summary card over the unpaid Credits.
class CreditSummary {
  const CreditSummary({
    required this.total,
    required this.other,
    required this.count,
    required this.unknownCount,
  });

  /// Known amounts in the shop's default currency.
  final Money total;

  /// The same Credits in the other currency, each converted with its own
  /// rate, so it is not just [total] converted again.
  final Money other;
  final int count;

  /// Credits with no amount yet.
  final int unknownCount;
}

/// Sums [unpaid] in [currency] and the other currency, each Credit
/// converted with its own snapshot.
CreditSummary summarize(Iterable<Credit> unpaid, Currency currency) {
  final otherCurrency = currency == Currency.khr ? Currency.usd : Currency.khr;
  var total = 0;
  var other = 0;
  var count = 0;
  var unknown = 0;
  for (final credit in unpaid) {
    count++;
    final inDefault = amountIn(credit, currency);
    if (inDefault == null) {
      unknown++;
      continue;
    }
    total += inDefault.amount;
    other += amountIn(credit, otherCurrency)!.amount;
  }
  return CreditSummary(
    total: Money(total, currency),
    other: Money(other, otherCurrency),
    count: count,
    unknownCount: unknown,
  );
}
