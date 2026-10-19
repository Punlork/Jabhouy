import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jabhouy_core/jabhouy_core.dart';
import 'package:jabhouy_l10n/jabhouy_l10n.dart';
import 'package:jabhouy_shop/jabhouy_shop.dart';
import 'package:jabhouy_ui/jabhouy_ui.dart';

void main() {
  late PriceRowDraft last;

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        locale: const Locale('km'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: PriceRowEditor(
            initial: const PriceRowDraft(id: 'r', currency: Currency.khr),
            settings: const PriceSettings(useWholesale: true),
            onChanged: (d) => last = d,
          ),
        ),
      ),
    );
  }

  Finder cost() => find.byType(TextField).at(4);

  testWidgets('cost takes numbers only, grouped in riel', (tester) async {
    await pump(tester);

    await tester.enterText(cost(), '4000abc');
    await tester.pump();
    expect(find.text('4,000'), findsOneWidget);
    expect(last.cost, '4,000');
  });

  testWidgets('switching the row to dollars converts wholesale and cost',
      (tester) async {
    await pump(tester);

    await tester.enterText(find.byType(TextField).at(3), '8000');
    await tester.enterText(cost(), '4000');
    await tester.tap(find.text(r'$'));
    await tester.pump();

    expect(find.text('2.00'), findsOneWidget);
    expect(find.text('1.00'), findsOneWidget);
    expect(last.currency, Currency.usd);
    expect((last.wholesale, last.cost), ('2.00', '1.00'));
  });
}
