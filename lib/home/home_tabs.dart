import 'package:jabhouy_core/jabhouy_core.dart';

/// The home tabs, in slot order.
///
/// A tab's [index] is also the slot it asks `TabScrollManager` for, so
/// hiding a tab must not renumber the others: the page maps what is
/// visible onto these slots instead.
enum HomeTab { shop, credit, income }

/// The tabs this build shows, left to right.
List<HomeTab> visibleHomeTabs(FeatureFlags flags) => [
      HomeTab.shop,
      HomeTab.credit,
      if (flags.isEnabled(Feature.income)) HomeTab.income,
    ];
