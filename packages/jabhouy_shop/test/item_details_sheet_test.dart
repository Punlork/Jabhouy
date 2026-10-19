import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jabhouy_core/jabhouy_core.dart';
import 'package:jabhouy_l10n/jabhouy_l10n.dart';
import 'package:jabhouy_shop/jabhouy_shop.dart';
import 'package:jabhouy_ui/jabhouy_ui.dart';

final _item = Item(
  id: 'coke',
  name: 'Coca-Cola',
  note: 'ដាក់នៅធ្នើទី ២',
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
    expect(find.text('ដើម: 2,500 ៛'), findsOneWidget, reason: 'cost for all');
    expect(find.text('ដើម: —'), findsOneWidget);
    expect(find.text('មិនទាន់មានតម្លៃ'), findsOneWidget);
    expect(find.text('ដាក់នៅធ្នើទី ២'), findsOneWidget, reason: 'the note');
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

  testWidgets('with many prices, header and buttons stay; prices scroll',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final many = Item(
      id: 'many',
      name: 'Many',
      prices: [
        for (var i = 0; i < 12; i++)
          PriceOption(
            id: 'p$i',
            unit: 'u$i',
            currency: Currency.khr,
            price: 1000 + i,
          ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        locale: const Locale('km'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              builder: (_) => ItemDetailsSheet(
                item: many,
                settings: const PriceSettings(),
                canEdit: true,
                onEdit: () {},
                onDelete: () {},
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    final screen = tester.getRect(find.byType(MaterialApp));
    bool onScreen(Finder f) => screen.contains(tester.getCenter(f));
    expect(onScreen(find.text('កែតម្លៃ')), isTrue, reason: 'buttons fixed');

    await tester.drag(find.text('1 u3'), const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(onScreen(find.text('Many')), isTrue, reason: 'header fixed');
    expect(onScreen(find.text('កែតម្លៃ')), isTrue);
    expect(find.text('1 u11'), findsOneWidget, reason: 'last price reached');
  });

  testWidgets('the ≈ line follows the shop setting', (tester) async {
    for (final show in [true, false]) {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          locale: const Locale('km'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: ItemDetailsSheet(
              item: _item,
              settings: PriceSettings(showConverted: show),
              canEdit: false,
              onEdit: () {},
              onDelete: () {},
            ),
          ),
        ),
      );
      expect(find.text(r'≈ $0.75'), show ? findsOneWidget : findsNothing);
    }
  });
}
