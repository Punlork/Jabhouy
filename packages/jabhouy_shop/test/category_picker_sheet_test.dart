import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jabhouy_l10n/jabhouy_l10n.dart';
import 'package:jabhouy_shop/jabhouy_shop.dart';
import 'package:jabhouy_ui/jabhouy_ui.dart';

const _categories = [
  ItemCategory(id: 'drinks', name: 'ភេសជ្ជៈ'),
  ItemCategory(id: 'rice', name: 'អង្ករ'),
  ItemCategory(id: 'old', name: 'Old', hidden: true),
];

void main() {
  String? picked;
  final created = <String>[];

  Future<void> open(WidgetTester tester) async {
    picked = null;
    created.clear();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        locale: const Locale('km'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async => picked = await showCategoryPicker(
              context,
              categories: _categories,
              selectedId: 'drinks',
              onCreate: (name) async {
                created.add(name);
                return 'new-id';
              },
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('lists visible categories, marks the chosen one, picks on tap',
      (tester) async {
    await open(tester);

    expect(find.text('Old'), findsNothing);
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    await tester.tap(find.text('អង្ករ'));
    await tester.pumpAndSettle();
    expect(picked, 'rice');
  });

  testWidgets('search narrows the list', (tester) async {
    await open(tester);

    await tester.enterText(find.byType(TextField), 'អង្ក');
    await tester.pump();
    expect(find.text('ភេសជ្ជៈ'), findsNothing);
    expect(find.text('អង្ករ'), findsOneWidget);
  });

  testWidgets('a new category is created and picked', (tester) async {
    await open(tester);

    await tester.tap(find.text('បង្កើតប្រភេទថ្មី'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'នំ');
    await tester.tap(find.text('រក្សាទុក'));
    await tester.pumpAndSettle();

    expect(created, ['នំ']);
    expect(picked, 'new-id');
  });
}
