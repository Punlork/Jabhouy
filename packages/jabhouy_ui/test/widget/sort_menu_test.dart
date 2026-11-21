import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jabhouy_ui/jabhouy_ui.dart';

void main() {
  testWidgets('the button names the order in use; a row picks or flips', (
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

    // In use and reversed: the button carries the reversed label.
    expect(find.text('Z–A'), findsOneWidget);
    expect(find.text('Newest'), findsNothing);

    await tester.tap(find.text('Z–A'));
    await tester.pumpAndSettle();
    // The list: the reversed label with a check, and the other order.
    expect(find.text('Z–A'), findsNWidgets(2));
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    expect(find.text('Newest'), findsOneWidget);

    await tester.tap(find.text('Newest'));
    await tester.pumpAndSettle();
    expect(calls, [('recent', null)]);
    expect(find.byIcon(Icons.check_rounded), findsNothing); // closed
  });
}
