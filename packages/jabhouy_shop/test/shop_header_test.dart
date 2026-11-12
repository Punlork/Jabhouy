import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jabhouy_l10n/jabhouy_l10n.dart';
import 'package:jabhouy_shop/jabhouy_shop.dart';
import 'package:jabhouy_ui/jabhouy_ui.dart';

void main() {
  Future<void> pumpHeader(WidgetTester tester, VoidCallback? onScan) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        locale: const Locale('km'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ShopHeader(
            hasFilter: false,
            onSettingsPressed: () {},
            onSearchChanged: (_) {},
            searchController: controller,
            onScanPressed: onScan,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('the scan button shows only when Home passes a scan', (
    tester,
  ) async {
    var scans = 0;
    await pumpHeader(tester, () => scans++);
    await tester.tap(find.byTooltip('ស្កេនបាកូដ'));
    expect(scans, 1);

    await pumpHeader(tester, null);
    expect(find.byTooltip('ស្កេនបាកូដ'), findsNothing);
  });
}
