import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jabhouy_ui/jabhouy_ui.dart';

import 'harness.dart';

void main() {
  testBothThemes(
    'SearchField shows its hint and reports typing',
    () => SearchField(hintText: 'ស្វែងរកទំនិញ', onChanged: (_) {}),
    (tester) async {
      expect(find.text('ស្វែងរកទំនិញ'), findsOneWidget);
      await expectAccessible(tester);
    },
  );

  var tapped = '';
  testBothThemes(
    'FilterChips hides a warning chip with count 0 and reports taps',
    () => FilterChips(
      items: [
        FilterChipItem(
          label: 'ទាំងអស់',
          selected: true,
          onTap: () => tapped = 'all',
        ),
        FilterChipItem(
          label: 'មិនទាន់មានតម្លៃ',
          selected: false,
          onTap: () {},
          warningCount: 0,
        ),
        FilterChipItem(
          label: 'ភេសជ្ជៈ',
          selected: false,
          onTap: () => tapped = 'drinks',
        ),
      ],
    ),
    (tester) async {
      expect(find.text('មិនទាន់មានតម្លៃ'), findsNothing);
      await tester.tap(find.text('ភេសជ្ជៈ'));
      expect(tapped, 'drinks');
      await expectAccessible(tester);
    },
  );

  testBothThemes(
    'FilterChips shows the warning chip with its count',
    () => FilterChips(
      items: [
        FilterChipItem(
          label: 'មិនទាន់មានតម្លៃ',
          selected: false,
          onTap: () {},
          warningCount: 3,
        ),
      ],
    ),
    (tester) async {
      expect(find.text('មិនទាន់មានតម្លៃ'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      await expectAccessible(tester);
    },
  );

  var picked = '';
  testBothThemes(
    'QuickPickChips reports the picked option',
    () => QuickPickChips(
      options: const ['ដប', 'កេះ'],
      selected: 'ដប',
      onPick: (v) => picked = v,
    ),
    (tester) async {
      await tester.tap(find.text('កេះ'));
      expect(picked, 'កេះ');
      await expectAccessible(tester);
    },
  );

  var currency = 'KHR';
  testBothThemes(
    'SegmentedControl reports the chosen option',
    () => SegmentedControl<String>(
      options: const [('KHR', '៛'), ('USD', r'$')],
      selected: 'KHR',
      onChanged: (v) => currency = v,
    ),
    (tester) async {
      await tester.tap(find.text(r'$'));
      expect(currency, 'USD');
      await expectAccessible(tester);
    },
  );

  testBothThemes(
    'StatusPill shows unpaid and paid in Khmer',
    () => const Column(
      children: [StatusPill(paid: false), StatusPill(paid: true)],
    ),
    (tester) async {
      expect(find.text('មិនទាន់សង'), findsOneWidget);
      expect(find.text('សងរួច'), findsOneWidget);
      await expectAccessible(tester);
    },
  );
}
