import 'package:flutter_test/flutter_test.dart';
import 'package:jabhouy/home/home_tabs.dart';
import 'package:jabhouy_core/jabhouy_core.dart';

void main() {
  test('income off hides its tab and keeps the others in their slots', () {
    final tabs = visibleHomeTabs(const FixedFeatureFlags({}));

    expect(tabs, [HomeTab.shop, HomeTab.loaner]);
    // Shop and loaner read their scroll controller by slot, so these must
    // not move when a tab disappears.
    expect(HomeTab.shop.index, 0);
    expect(HomeTab.loaner.index, 1);
  });

  test('income on shows every tab, income last', () {
    final tabs = visibleHomeTabs(const FixedFeatureFlags({Feature.income}));

    expect(tabs, [HomeTab.shop, HomeTab.loaner, HomeTab.income]);
    expect(HomeTab.income.index, 2);
  });
}
