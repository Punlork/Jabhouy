import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jabhouy_ui/jabhouy_ui.dart';

Future<void> _pumpAt(WidgetTester tester, double width, Widget child) async {
  tester.view
    ..physicalSize = Size(width, 800)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    Directionality(textDirection: TextDirection.ltr, child: child),
  );
}

void main() {
  test('gridColumns steps 2, 3, 4 at the breakpoints', () {
    expect(AppBreakpoints.gridColumns(400), 2);
    expect(AppBreakpoints.gridColumns(599), 2);
    expect(AppBreakpoints.gridColumns(600), 3);
    expect(AppBreakpoints.gridColumns(899), 3);
    expect(AppBreakpoints.gridColumns(900), 4);
  });

  testWidgets('ContentWidth.form caps and centers on a wide screen', (
    tester,
  ) async {
    await _pumpAt(
      tester,
      1000,
      const ContentWidth.form(child: SizedBox.expand(key: Key('c'))),
    );
    final box = tester.getRect(find.byKey(const Key('c')));
    expect(box.width, AppBreakpoints.maxFormWidth);
    expect(box.center.dx, 500);
  });

  testWidgets('ContentWidth leaves a phone alone', (tester) async {
    await _pumpAt(
      tester,
      400,
      const ContentWidth.form(child: SizedBox.expand(key: Key('c'))),
    );
    expect(tester.getRect(find.byKey(const Key('c'))).width, 400);
  });
}
