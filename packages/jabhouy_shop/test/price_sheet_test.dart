import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jabhouy_core/jabhouy_core.dart';
import 'package:jabhouy_l10n/jabhouy_l10n.dart';
import 'package:jabhouy_shop/jabhouy_shop.dart';
import 'package:jabhouy_ui/jabhouy_ui.dart';

void main() {
  late PriceSheetResult? result;

  Future<void> open(
    WidgetTester tester, {
    PriceRowDraft initial = const PriceRowDraft(
      id: 'r',
      currency: Currency.khr,
    ),
    bool isNew = false,
    PriceSettings settings = const PriceSettings(),
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 1600);
    addTearDown(tester.view.reset);
    result = null;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        locale: const Locale('km'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async => result = await showPriceSheet(
              context,
              initial: initial,
              isNew: isNew,
              settings: settings,
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('new: បន្ថែម returns the typed row; nothing typed adds nothing', (
    tester,
  ) async {
    await open(tester, isNew: true);
    expect(find.text('តម្លៃថ្មី'), findsOneWidget);
    expect(find.text('លុបតម្លៃនេះ'), findsNothing);

    await tester.enterText(find.byType(TextField).first, 'ដប');
    await tester.enterText(find.byType(TextField).at(2), '3000');
    await tester.tap(find.text('បន្ថែម'));
    await tester.pumpAndSettle();

    expect(result, isA<PriceSaved>());
    final draft = (result! as PriceSaved).draft;
    expect((draft.unit, draft.price), ('ដប', '3,000'));

    await open(tester, isNew: true);
    await tester.tap(find.text('បន្ថែម'));
    await tester.pumpAndSettle();
    expect(result, isNull);
  });

  testWidgets('a bad price stays open and says why', (tester) async {
    await open(
      tester,
      initial: const PriceRowDraft(
        id: 'r',
        currency: Currency.khr,
        unit: 'ដប',
        packQty: '0',
      ),
    );

    await tester.tap(find.text('រួចរាល់'));
    await tester.pumpAndSettle();

    expect(find.text('ចំនួនត្រូវធំជាង ០'), findsOneWidget);
    expect(result, isNull);
    expect(find.text('កែតម្លៃ'), findsOneWidget, reason: 'sheet still open');
  });

  testWidgets('edit: លុបតម្លៃនេះ returns a delete', (tester) async {
    await open(
      tester,
      initial: const PriceRowDraft(id: 'r', currency: Currency.khr, unit: 'ដប'),
    );
    await tester.tap(find.text('លុបតម្លៃនេះ'));
    await tester.pumpAndSettle();
    expect(result, isA<PriceDeleted>());
  });

  testWidgets('the sheet is as tall as its form, not a fixed share', (
    tester,
  ) async {
    await open(tester, isNew: true);
    // The test screen is 1600 tall; the form needs well under half.
    expect(tester.getSize(find.byType(AppSheet)).height, lessThan(800));
  });

  testWidgets('keyboard: Next walks unit → count → price → wholesale → cost, '
      'Done on the last one adds the row', (tester) async {
    await open(
      tester,
      isNew: true,
      settings: const PriceSettings(useWholesale: true),
    );
    // A new price opens with the cursor in the unit field.
    expect(
      tester.widget<TextField>(find.byType(TextField).first).autofocus,
      isTrue,
    );

    await tester.enterText(find.byType(TextField).at(0), 'ដប');
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pump();
    await tester.enterText(find.byType(TextField).at(1), '12');
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pump();
    await tester.enterText(find.byType(TextField).at(2), '3000');
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pump();
    await tester.enterText(find.byType(TextField).at(3), '2800');
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pump();
    await tester.enterText(find.byType(TextField).at(4), '2500');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(result, isA<PriceSaved>());
    final draft = (result! as PriceSaved).draft;
    expect(
      (draft.unit, draft.packQty, draft.price, draft.wholesale, draft.cost),
      ('ដប', '12', '3,000', '2,800', '2,500'),
    );
  });

  testWidgets('keyboard: Done on the price adds the row when it is the last '
      'field', (tester) async {
    await open(
      tester,
      isNew: true,
      settings: const PriceSettings(useCost: false),
    );
    await tester.enterText(find.byType(TextField).at(0), 'ដប');
    await tester.enterText(find.byType(TextField).at(2), '3000');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(result, isA<PriceSaved>());
  });
}
