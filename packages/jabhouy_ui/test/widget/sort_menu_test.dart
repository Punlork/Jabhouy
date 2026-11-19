import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jabhouy_ui/jabhouy_ui.dart';

void main() {
  testWidgets('a row flips the order in use; an arrow sets its direction', (
    tester,
  ) async {
    final calls = <(String, bool?)>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: SortMenu<String>(
            tooltip: 'Sort',
            options: const [
              ('name', Icons.sort_by_alpha_rounded, 'A–Z', 'Z–A'),
              ('recent', Icons.schedule_rounded, 'Newest', 'Oldest'),
            ],
            selected: 'name',
            reversed: true,
            onChanged: (v, {reversed}) => calls.add((v, reversed)),
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.sort_rounded));
    await tester.pumpAndSettle();
    // In use and reversed: the reversed label; the other row its own.
    expect(find.text('Z–A'), findsOneWidget);
    expect(find.text('Newest'), findsOneWidget);
    await tester.tap(find.text('Z–A'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.sort_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.arrow_upward_rounded).last);
    await tester.pumpAndSettle();

    expect(calls, [('name', null), ('recent', true)]);
    expect(find.text('Newest'), findsNothing); // the menu closed
  });
}
