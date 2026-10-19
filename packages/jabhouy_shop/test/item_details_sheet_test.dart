import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jabhouy_core/jabhouy_core.dart';
import 'package:jabhouy_l10n/jabhouy_l10n.dart';
import 'package:jabhouy_shop/jabhouy_shop.dart';
import 'package:jabhouy_ui/jabhouy_ui.dart';

final _item = Item(
  id: 'coke',
  name: 'Coca-Cola',
  categoryId: 'drinks',
  updatedAt: DateTime.utc(2026, 10, 19, 3),
  prices: const [
    PriceOption(
      id: 'p1',
      unit: 'ដប',
      currency: Currency.khr,
      price: 3000,
      cost: 2500,
    ),
    PriceOption(id: 'p2', unit: 'កេះ', packQty: 24, currency: Currency.khr),
  ],
);

void main() {
  final events = <String>[];

  Future<void> pumpSheet(
    WidgetTester tester, {
    required bool canEdit,
    String? editorName,
  }) async {
    events.clear();
    await tester.binding.setSurfaceSize(const Size(390, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        locale: const Locale('km'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ItemDetailsSheet(
            item: _item,
            categoryName: 'ភេសជ្ជៈ',
            settings: const PriceSettings(),
            canEdit: canEdit,
            editorName: editorName,
            onEdit: () => events.add('edit'),
            onDelete: () => events.add('delete'),
          ),
        ),
      ),
    );
  }

  testWidgets('a viewer sees prices and cost but no edit or delete',
      (tester) async {
    await pumpSheet(tester, canEdit: false);

    expect(find.text('Coca-Cola'), findsOneWidget);
    expect(find.text('ភេសជ្ជៈ'), findsOneWidget);
    expect(find.text('1 កេះ · ×24'), findsOneWidget);
    expect(find.text('3,000 ៛'), findsOneWidget);
    expect(find.text('2,500 ៛'), findsOneWidget, reason: 'cost for everyone');
    expect(find.text('មិនទាន់មានតម្លៃ'), findsOneWidget);
    expect(find.text('កែតម្លៃ'), findsNothing);
    expect(find.text('លុប'), findsNothing);
  });

  testWidgets('an editor gets edit, and delete only after confirming',
      (tester) async {
    await pumpSheet(tester, canEdit: true);

    await tester.tap(find.text('កែតម្លៃ'));
    expect(events, ['edit']);

    await tester.tap(find.text('លុប'));
    await tester.pumpAndSettle();
    expect(events, ['edit'], reason: 'nothing deleted before confirming');
    await tester.tap(find.text('លុប').last);
    await tester.pumpAndSettle();
    expect(events, ['edit', 'delete']);
  });

  testWidgets('last edited shows the Phnom Penh day, and a name when known',
      (tester) async {
    await pumpSheet(tester, canEdit: false);
    expect(find.text('កែចុងក្រោយ 19 តុលា 2026'), findsOneWidget);

    await pumpSheet(tester, canEdit: false, editorName: 'ដារ៉ា');
    expect(find.text('កែចុងក្រោយ 19 តុលា 2026 ដោយ ដារ៉ា'), findsOneWidget);
  });
}
