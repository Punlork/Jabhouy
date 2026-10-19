import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jabhouy_ui/jabhouy_ui.dart';

import 'harness.dart';

void main() {
  testBothThemes(
    'AppSheet keeps the footer visible while long content scrolls',
    () => SizedBox(
      height: 500,
      child: AppSheet(
        title: 'ជ្រើសទំនិញ',
        footer: FilledButton(
          onPressed: () {},
          child: const Text('បន្ថែមទៅការជំពាក់'),
        ),
        child: Column(
          children: [
            for (var i = 0; i < 40; i++)
              SizedBox(height: 48, child: Text('ទំនិញ $i')),
          ],
        ),
      ),
    ),
    (tester) async {
      expect(find.text('ជ្រើសទំនិញ'), findsOneWidget);
      expect(find.text('ទំនិញ 39').hitTestable(), findsNothing);
      final footer = find.text('បន្ថែមទៅការជំពាក់');
      expect(footer.hitTestable(), findsOneWidget);
      await tester.drag(find.text('ទំនិញ 3'), const Offset(0, -2000));
      await tester.pumpAndSettle();
      expect(find.text('ទំនិញ 39').hitTestable(), findsOneWidget);
      expect(footer.hitTestable(), findsOneWidget);
      await expectAccessible(tester);
    },
  );

  testWidgets('AppSheet close button pops the sheet', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              builder: (_) =>
                  const AppSheet(title: 'ជ្រើសទំនិញ', child: Text('x')),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('ជ្រើសទំនិញ'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();
    expect(find.text('ជ្រើសទំនិញ'), findsNothing);
  });

  testWidgets('showAppSheet opens part way and grows as its content scrolls',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => showAppSheet<void>(
              context,
              initialSize: 0.5,
              builder: (context, controller) => AppSheet(
                title: 'ទំនិញ',
                scrollController: controller,
                footer: const Text('footer'),
                child: Column(
                  children: [
                    for (var i = 0; i < 40; i++)
                      SizedBox(height: 48, child: Text('row $i')),
                  ],
                ),
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    double sheetHeight() => tester.getSize(find.byType(AppSheet)).height;
    expect(sheetHeight(), closeTo(400, 40), reason: 'half of 800');
    expect(find.text('footer').hitTestable(), findsOneWidget);

    await tester.drag(find.text('row 2'), const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(sheetHeight(), greaterThan(600), reason: 'it grew first');
    expect(find.text('ទំនិញ').hitTestable(), findsOneWidget);
    expect(find.text('footer').hitTestable(), findsOneWidget);
  });
}
