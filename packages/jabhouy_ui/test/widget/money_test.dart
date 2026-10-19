import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jabhouy_core/jabhouy_core.dart';
import 'package:jabhouy_ui/jabhouy_ui.dart';

import 'harness.dart';

void main() {
  testBothThemes(
    'PriceDisplay shows a missing price as មិនទាន់មានតម្លៃ, never 0',
    () => const PriceDisplay(price: null, khrPerUsd: 4000, showConverted: true),
    (tester) async {
      expect(find.text('មិនទាន់មានតម្លៃ'), findsOneWidget);
      expect(find.textContaining('0 ៛'), findsNothing);
      await expectAccessible(tester);
    },
  );

  testBothThemes(
    'PriceDisplay shows the converted line only when asked',
    () => const Column(
      children: [
        PriceDisplay(
          price: Money(750, Currency.usd),
          khrPerUsd: 4000,
          showConverted: true,
        ),
        PriceDisplay(
          price: Money(3800, Currency.khr),
          khrPerUsd: 4000,
          showConverted: false,
        ),
      ],
    ),
    (tester) async {
      expect(find.text(r'$7.50'), findsOneWidget);
      expect(find.text('≈ 30,000 ៛'), findsOneWidget);
      expect(find.text('3,800 ៛'), findsOneWidget);
      expect(find.text(r'≈ $0.95'), findsNothing);
      await expectAccessible(tester);
    },
  );

  final reported = <Money?>[];
  Widget input(Currency c) =>
      MoneyInput(currency: c, khrPerUsd: 4000, onChanged: reported.add);

  testBothThemes(
    'MoneyInput in dollars shows the riel hint',
    () => input(Currency.usd),
    (tester) async {
      reported.clear();
      await tester.enterText(find.byType(TextField), '7.5');
      await tester.pump();
      expect(find.text('≈ 30,000 ៛'), findsOneWidget);
      expect(reported.last, const Money(750, Currency.usd));
      await expectAccessible(tester);
    },
  );

  testBothThemes(
    'MoneyInput groups riel while typing and reports null when cleared',
    () => input(Currency.khr),
    (tester) async {
      reported.clear();
      await tester.enterText(find.byType(TextField), '30000');
      await tester.pump();
      expect(find.text('30,000'), findsOneWidget);
      expect(reported.last, const Money(30000, Currency.khr));
      await tester.enterText(find.byType(TextField), '');
      await tester.pump();
      expect(reported.last, isNull);
      expect(find.textContaining('≈'), findsNothing);
    },
  );

  final texts = <(String, Currency)>[];
  testBothThemes(
    'MoneyInput keeps a riel decimal visible instead of losing the dot',
    () => MoneyInput(
      currency: Currency.khr,
      khrPerUsd: 4000,
      onText: (text, currency) => texts.add((text, currency)),
      errorText: 'តម្លៃរៀលមិនអាចមានទសភាគ',
    ),
    (tester) async {
      texts.clear();
      await tester.enterText(find.byType(TextField), '3000.5');
      await tester.pump();
      expect(find.text('3000.5'), findsOneWidget);
      expect(texts.last, ('3000.5', Currency.khr));
      expect(find.text('តម្លៃរៀលមិនអាចមានទសភាគ'), findsOneWidget);
      await tester.tap(find.text(r'$'));
      await tester.pump();
      expect(texts.last.$2, Currency.usd, reason: 'a switch is reported too');
    },
  );

  testBothThemes(
    'MoneyInput toggle converts the value',
    () => input(Currency.khr),
    (tester) async {
      reported.clear();
      await tester.enterText(find.byType(TextField), '30000');
      await tester.tap(find.text(r'$'));
      await tester.pump();
      expect(find.text('7.50'), findsOneWidget);
      expect(reported.last, const Money(750, Currency.usd));
      expect(find.text('≈ 30,000 ៛'), findsOneWidget);
    },
  );
}
