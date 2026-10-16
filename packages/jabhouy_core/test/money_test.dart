import 'package:jabhouy_core/jabhouy_core.dart';
import 'package:test/test.dart';

void main() {
  const rate = 4000;

  group('convertTo', () {
    test('matches the API test cases at 4,000', () {
      expect(
        const Money(750, Currency.usd).convertTo(Currency.khr, khrPerUsd: rate),
        const Money(30000, Currency.khr),
      );
      expect(
        const Money(3800, Currency.khr).convertTo(Currency.usd, khrPerUsd: rate),
        const Money(95, Currency.usd),
      );
      expect(
        const Money(123, Currency.usd).convertTo(Currency.khr, khrPerUsd: rate),
        const Money(4900, Currency.khr),
      );
    });

    test('rounds riel half up to the nearest 100', () {
      // $0.99 at 5,000 is exactly 4,950 ៛.
      expect(
        const Money(99, Currency.usd).convertTo(Currency.khr, khrPerUsd: 5000),
        const Money(5000, Currency.khr),
      );
    });

    test('rounds cents half up', () {
      // 20 ៛ at 4,000 is exactly half a cent.
      expect(
        const Money(20, Currency.khr).convertTo(Currency.usd, khrPerUsd: rate),
        const Money(1, Currency.usd),
      );
      expect(
        const Money(19, Currency.khr).convertTo(Currency.usd, khrPerUsd: rate),
        const Money(0, Currency.usd),
      );
    });

    test('to the same currency returns the same amount', () {
      const m = Money(4920, Currency.khr);
      expect(m.convertTo(Currency.khr, khrPerUsd: rate), m);
    });
  });

  group('format', () {
    test('riel is grouped with the riel sign after', () {
      expect(const Money(30000, Currency.khr).format(), '30,000 ៛');
      expect(const Money(1234567, Currency.khr).format(), '1,234,567 ៛');
      expect(const Money(500, Currency.khr).format(), '500 ៛');
    });

    test('dollars have two decimals', () {
      expect(const Money(750, Currency.usd).format(), r'$7.50');
      expect(const Money(5, Currency.usd).format(), r'$0.05');
      expect(const Money(123456789, Currency.usd).format(), r'$1,234,567.89');
    });

    test('approx adds the ≈ prefix', () {
      expect(const Money(95, Currency.usd).formatApprox(), r'≈ $0.95');
    });
  });
}
