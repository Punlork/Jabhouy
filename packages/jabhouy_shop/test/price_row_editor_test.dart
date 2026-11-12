import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jabhouy_core/jabhouy_core.dart';
import 'package:jabhouy_l10n/jabhouy_l10n.dart';
import 'package:jabhouy_shop/jabhouy_shop.dart';
import 'package:jabhouy_ui/jabhouy_ui.dart';

void main() {
  late PriceRowDraft last;

  Future<void> pump(
    WidgetTester tester, {
    List<String> unitChips = const [],
  }) async {
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
            unitChips: unitChips,
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

  testWidgets('five unit chips, the rest behind ទាំងអស់ ›', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 1600);
    addTearDown(tester.view.reset);
    await pump(tester, unitChips: [for (var i = 1; i <= 7; i++) 'u$i']);

    expect(find.text('u5'), findsOneWidget);
    expect(find.text('u6'), findsNothing);

    await tester.tap(find.text('ទាំងអស់ ›'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('u7'));
    await tester.pumpAndSettle();

    expect(last.unit, 'u7');
  });
}
