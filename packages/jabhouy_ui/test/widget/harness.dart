import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jabhouy_l10n/jabhouy_l10n.dart';
import 'package:jabhouy_ui/jabhouy_ui.dart';

/// Runs [body] once per theme with [child] pumped in Khmer.
void testBothThemes(
  String description,
  Widget Function() child,
  Future<void> Function(WidgetTester tester) body,
) {
  for (final (name, theme) in [
    ('light', AppTheme.lightTheme),
    ('dark', AppTheme.darkTheme),
  ]) {
    testWidgets('$description ($name)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          locale: const Locale('km'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Padding(padding: const EdgeInsets.all(16), child: child()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await body(tester);
    });
  }
}

/// Every tap target is at least 44 × 44 and text meets contrast.
Future<void> expectAccessible(WidgetTester tester) async {
  await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
  await expectLater(tester, meetsGuideline(textContrastGuideline));
}
