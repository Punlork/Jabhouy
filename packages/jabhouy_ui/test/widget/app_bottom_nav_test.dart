import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jabhouy_ui/jabhouy_ui.dart';

import 'harness.dart';

void main() {
  var tab = -1;
  var actions = 0;
  Widget nav(int selected) => Align(
    alignment: Alignment.bottomCenter,
    child: AppBottomNav(
      tabs: const [
        AppNavTab(icon: Icons.storefront_rounded, label: 'ហាង'),
        AppNavTab(icon: Icons.menu_book_rounded, label: 'ជំពាក់'),
      ],
      selectedIndex: selected,
      onTabChanged: (i) => tab = i,
      actionLabel: selected == 0 ? 'បន្ថែមទំនិញ' : 'បន្ថែមការជំពាក់',
      onAction: () => actions++,
    ),
  );

  testBothThemes(
    'AppBottomNav reports tab taps and runs the shop action',
    () => nav(0),
    (tester) async {
      tab = -1;
      actions = 0;
      expect(find.text('ហាង'), findsOneWidget);
      expect(find.text('ជំពាក់'), findsOneWidget);
      await tester.tap(find.text('ជំពាក់'));
      expect(tab, 1);
      await tester.tap(find.text('បន្ថែមទំនិញ'));
      expect(actions, 1);
      await expectAccessible(tester);
    },
  );

  testBothThemes(
    'AppBottomNav shows the credit action on the credit tab',
    () => nav(1),
    (tester) async {
      expect(find.text('បន្ថែមការជំពាក់'), findsOneWidget);
      expect(find.text('បន្ថែមទំនិញ'), findsNothing);
      await expectAccessible(tester);
    },
  );
}
