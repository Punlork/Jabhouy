import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jabhouy_ui/jabhouy_ui.dart';

import 'harness.dart';

void main() {
  testBothThemes(
    'LabeledField puts the label above with an optional suffix and hint',
    () => const LabeledField(
      label: 'កំណត់ចំណាំ',
      optional: true,
      hint: 'គណនាពីទំនិញ',
      child: TextField(),
    ),
    (tester) async {
      expect(find.textContaining('កំណត់ចំណាំ'), findsOneWidget);
      expect(find.textContaining('(មិនចាំបាច់)'), findsOneWidget);
      expect(find.text('គណនាពីទំនិញ'), findsOneWidget);
      final label = tester.getRect(find.textContaining('កំណត់ចំណាំ'));
      final field = tester.getRect(find.byType(TextField));
      expect(label.bottom, lessThanOrEqualTo(field.top));
      await expectAccessible(tester);
    },
  );

  testBothThemes(
    'LabeledField without optional has no suffix',
    () => const LabeledField(label: 'ឈ្មោះទំនិញ', child: TextField()),
    (tester) async {
      expect(find.textContaining('(មិនចាំបាច់)'), findsNothing);
    },
  );

  final values = <int>[];
  testBothThemes(
    'QtyStepper adds and removes',
    () => QtyStepper(value: 1, onChanged: values.add),
    (tester) async {
      values.clear();
      await tester.tap(find.byIcon(Icons.add_rounded));
      await tester.tap(find.byIcon(Icons.remove_rounded));
      expect(values, [2, 0]);
      await expectAccessible(tester);
    },
  );

  testBothThemes(
    'QtyStepper cannot go below 0',
    () => QtyStepper(value: 0, onChanged: values.add),
    (tester) async {
      values.clear();
      await tester.tap(find.byIcon(Icons.remove_rounded));
      expect(values, isEmpty);
      await expectAccessible(tester);
    },
  );

  testBothThemes(
    'DateTimeField shows the date and an add-time prompt',
    () => DateTimeField(
      date: DateTime(2026, 10, 16),
      dateText: '16 តុលា 2026',
      onDateChanged: (_) {},
      onTimeChanged: (_) {},
    ),
    (tester) async {
      expect(find.text('16 តុលា 2026'), findsOneWidget);
      expect(find.text('បន្ថែមម៉ោង'), findsOneWidget);
      await expectAccessible(tester);
    },
  );

  DateTime? picked;
  testBothThemes(
    'DateTimeField opens the date picker and reports the pick',
    () => DateTimeField(
      date: DateTime(2026, 10, 16),
      dateText: '16 តុលា 2026',
      timeText: '11:05 ព្រឹក',
      time: const TimeOfDay(hour: 11, minute: 5),
      onDateChanged: (d) => picked = d,
      onTimeChanged: (_) {},
    ),
    (tester) async {
      picked = null;
      expect(find.text('11:05 ព្រឹក'), findsOneWidget);
      await tester.tap(find.text('16 តុលា 2026'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('20'));
      await tester.tap(find.byType(TextButton).last);
      await tester.pumpAndSettle();
      expect(picked, DateTime(2026, 10, 20));
    },
  );
}
