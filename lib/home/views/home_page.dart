import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:jabhouy/app/app.dart';
import 'package:jabhouy/auth/auth.dart';
import 'package:jabhouy/customer/customer.dart';
import 'package:jabhouy/home/home_tabs.dart';
import 'package:jabhouy/income/income.dart';
import 'package:jabhouy/loaner/loaner.dart';
import 'package:jabhouy_core/jabhouy_core.dart';
import 'package:jabhouy_l10n/jabhouy_l10n.dart';
import 'package:jabhouy_net/jabhouy_net.dart';
import 'package:jabhouy_shop/jabhouy_shop.dart';
import 'package:jabhouy_sync/jabhouy_sync.dart';
import 'package:jabhouy_ui/jabhouy_ui.dart';


class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  late final List<ScrollController> _scrollControllers;
  int _selectedIndex = 0;
  late final PageController _pageController;
  bool _hasLoadedProtectedData = false;
  final _tabs = visibleHomeTabs(getIt<FeatureFlags>());

  HomeTab get _selectedTab => _tabs[_selectedIndex];
  bool get _isIncomeEnabled => _tabs.contains(HomeTab.income);
  final _isBackgroundSyncEnabled =
      getIt<FeatureFlags>().isEnabled(Feature.backgroundSync);

  /// Search header and bottom bar slide away while scrolling down a list
  /// and come back on any scroll up. Category chips live in the tab, so
  /// they stay put and move up into the header's place.
  final _bottomBarController = BottomBarController();
  bool _chromeVisible = true;
  double _scrollRun = 0;
  static const _chromeScrollThreshold = 12.0;

  void _setChromeVisible(bool visible) {
    _scrollRun = 0;
    if (_chromeVisible == visible) return;
    setState(() => _chromeVisible = visible);
    visible ? _bottomBarController.show() : _bottomBarController.hide();
  }

  bool _onPageScroll(ScrollUpdateNotification notification) {
    final metrics = notification.metrics;
    // Category chips scroll sideways; only the tab's list counts.
    if (metrics.axis != Axis.vertical) return false;

    // At the top, pulling to refresh or scrolled back by code: show.
    if (metrics.pixels <= metrics.minScrollExtent) {
      _setChromeVisible(true);
      return false;
    }
    // The bounce past the end, and the viewport growing as the header
    // collapses, both read as scrolling up; neither should bring it back.
    if (metrics.pixels >= metrics.maxScrollExtent) return false;

    final delta = notification.scrollDelta ?? 0;
    if (delta == 0) return false;
    if (delta.sign != _scrollRun.sign) _scrollRun = 0;
    _scrollRun += delta;

    if (_scrollRun <= -_chromeScrollThreshold) {
      _setChromeVisible(true);
    } else if (_scrollRun >= _chromeScrollThreshold &&
        _searchController.text.isEmpty) {
      // A search in progress keeps its field on screen.
      _setChromeVisible(false);
    }
    return false;
  }

  static Widget _pageFor(HomeTab tab) => switch (tab) {
        HomeTab.shop => const ShopTab(),
        HomeTab.loaner => const LoanerView(),
        HomeTab.income => const IncomeView(),
      };

  void _onItemTapped(int index) {
    if (index == _selectedIndex) {
      final controller = _scrollControllers[_tabs[index].index];
      if (!controller.hasClients) return;
      controller.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      _selectedIndex = index;
    }
    _pageController.jumpToPage(_selectedIndex);
  }

  void _onSearchChanged(String? value) {
    switch (_selectedTab) {
      case HomeTab.shop:
        context.read<ShopBloc>().add(
              ShopGetItemsEvent(
                searchQuery: value,
                categoryFilter: context.read<ShopBloc>().state.asLoaded?.categoryFilter,
              ),
            );
      case HomeTab.loaner:
        context.read<LoanerBloc>().add(LoadLoaners(searchQuery: value));
      case HomeTab.income:
        context.read<IncomeBloc>().add(LoadIncomeDashboard(searchQuery: value));
    }
  }

  void _showFilterSheet() {
    switch (_selectedTab) {
      case HomeTab.shop:
        showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          builder: (_) => MultiBlocProvider(
            providers: [
              BlocProvider.value(value: context.read<CategoryBloc>()),
              BlocProvider.value(value: context.read<ShopBloc>()),
            ],
            child: FilterSheet(
              initialCategoryFilter: context.read<ShopBloc>().state.asLoaded?.categoryFilter,
              onApply: (category) => context.read<ShopBloc>().add(
                    ShopGetItemsEvent(
                      categoryFilter: category,
                      clearCategoryFilter: category == null,
                    ),
                  ),
            ),
          ),
        );
      case HomeTab.loaner:
        showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          builder: (_) => MultiBlocProvider(
            providers: [
              BlocProvider.value(value: context.read<LoanerBloc>()),
              BlocProvider.value(value: context.read<CustomerBloc>()),
            ],
            child: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: LoanerFilterSheet(
                initialFromDate: context.read<LoanerBloc>().state.asLoaded?.fromDate,
                initialToDate: context.read<LoanerBloc>().state.asLoaded?.toDate,
                initialLoanerFilter: context.read<LoanerBloc>().state.asLoaded?.loanerFilter,
                onApply: (fromDate, toDate, loanerFilter) => context.read<LoanerBloc>().add(
                      LoadLoaners(
                        fromDate: fromDate,
                        toDate: toDate,
                        loanerFilter: loanerFilter,
                      ),
                    ),
              ),
            ),
          ),
        );
      case HomeTab.income:
        showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          builder: (_) => BlocProvider.value(
            value: context.read<IncomeBloc>(),
            child: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: IncomeFilterSheet(
                initialFromDate: context.read<IncomeBloc>().state.asLoaded?.fromDate,
                initialToDate: context.read<IncomeBloc>().state.asLoaded?.toDate,
                initialBankFilter: context.read<IncomeBloc>().state.asLoaded?.bankFilter,
                initialRecordFilter:
                    context.read<IncomeBloc>().state.asLoaded?.recordFilter ?? NotificationRecordFilter.all,
                onApply: (fromDate, toDate, bankFilter, recordFilter) => context.read<IncomeBloc>().add(
                      LoadIncomeDashboard(
                        fromDate: fromDate,
                        toDate: toDate,
                        bankFilter: bankFilter,
                        recordFilter: recordFilter,
                      ),
                    ),
              ),
            ),
          ),
        );
    }
  }

  void _openSettingsPage() {
    context.pushNamed(
      AppRoutes.settings,
      extra: {
        'category': context.read<CategoryBloc>(),
        'shop': context.read<ShopBloc>(),
        'customerBloc': context.read<CustomerBloc>(),
        if (_isIncomeEnabled) 'incomeBloc': context.read<IncomeBloc>(),
        'signoutBloc': context.read<SignoutBloc>(),
      },
    );
  }

  void _openShopForm() {
    final activeCategory = context.read<ShopBloc>().state.asLoaded?.categoryFilter;
    context.pushNamed(
      AppRoutes.formShop,
      extra: {
        'shop': context.read<ShopBloc>(),
        'category': context.read<CategoryBloc>(),
        'activeCategory': activeCategory,
        'onAdd': (ShopItemModel item) {},
      },
    );
  }

  void _openLoanerForm() {
    context.pushNamed(
      AppRoutes.formLoaner,
      extra: {
        'loanerBloc': context.read<LoanerBloc>(),
        'customerBloc': context.read<CustomerBloc>(),
      },
    );
  }

  void _seedIncomeDemoData(AppState appState) {
    if (appState.deviceRole.isSub) {
      showErrorSnackBar(null, context.l10n.mainDeviceRoleRequired);
      return;
    }

    final trackingStatus = context.read<IncomeBloc>().state.asLoaded?.trackingStatus;
    if (trackingStatus?.isBlockedByAnotherMainDevice ?? false) {
      showErrorSnackBar(null, context.l10n.anotherMainDeviceActive);
      return;
    }

    context.read<IncomeBloc>().add(
          SeedIncomeDemoData(
            context.l10n.demoDataAdded,
            context.l10n.anotherMainDeviceActive,
          ),
        );
  }

  _BottomActionConfig? _buildBottomActionConfig(AppState appState) {
    switch (_selectedTab) {
      case HomeTab.shop:
        return _BottomActionConfig(
          tooltip: context.l10n.addItem,
          iconAsset: AppAssets.actionAddShop,
          onPressed: _openShopForm,
        );
      case HomeTab.loaner:
        return _BottomActionConfig(
          tooltip: context.l10n.addLoaner,
          iconAsset: AppAssets.actionAddLoaner,
          onPressed: _openLoanerForm,
        );
      case HomeTab.income:
        if (kReleaseMode) {
          return _BottomActionConfig(
            tooltip: context.l10n.refreshStatus,
            iconAsset: AppAssets.actionRefresh,
            onPressed: () => context.read<IncomeBloc>().add(
                  const RefreshIncomeTrackingStatus(),
                ),
          );
        }

        final isMainDevice = appState.deviceRole.isMain;
        final isBlocked =
            context.read<IncomeBloc>().state.asLoaded?.trackingStatus?.isBlockedByAnotherMainDevice ?? false;

        return _BottomActionConfig(
          tooltip: isMainDevice ? context.l10n.addDemoData : context.l10n.mainDeviceOnly,
          iconAsset: AppAssets.actionDemo,
          onPressed: isMainDevice && !isBlocked ? () => _seedIncomeDemoData(appState) : null,
        );
    }
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
    // One per slot, not per visible tab: see HomeTab.
    _scrollControllers = [
      for (final _ in HomeTab.values) ScrollController(),
    ];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final authState = context.read<AuthBloc>().state;
      if (authState is Authenticated) {
        _loadProtectedData();
      }
    });
  }

  void _loadProtectedData() {
    if (_hasLoadedProtectedData) return;

    _hasLoadedProtectedData = true;
    context.read<LoanerBloc>().add(LoadLoaners());
    context.read<ShopBloc>().add(ShopGetItemsEvent());
    context.read<CategoryBloc>().add(CategoryGetEvent());
    context.read<CustomerBloc>().add(LoadCustomers());
    // With background sync the loads above only read the phone; this is
    // what brings the lists up to date.
    if (_isBackgroundSyncEnabled) getIt<SyncCoordinator>().start();
    if (_isIncomeEnabled) {
      context.read<IncomeBloc>().add(const RefreshIncomeTrackingStatus());
    }
  }

  @override
  void dispose() {
    for (final controller in _scrollControllers) {
      controller.dispose();
    }
    _pageController.dispose();
    _searchController.dispose();
    _bottomBarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (previous, current) => previous.runtimeType != current.runtimeType,
      listener: (context, authState) {
        if (authState is Authenticated) {
          _loadProtectedData();
          return;
        }

        if (authState is Unauthenticated) {
          context.go(AppRoutes.signin.toPath);
          _hasLoadedProtectedData = false;
          getIt<SyncCoordinator>().stop();
        }
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          if (authState is! Authenticated) {
            return const Scaffold(
              body: SizedBox.expand(),
            );
          }

          return _buildAuthenticatedScaffold(context);
        },
      ),
    );
  }

  Widget _buildAuthenticatedScaffold(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final appState = context.watch<AppBloc>().state;
    final bottomAction = _buildBottomActionConfig(appState);
    final bottomBarBackground = isDark ? colorScheme.surfaceContainerLow : colorScheme.surface;
    final bottomBarIndicator = isDark ? colorScheme.primary : colorScheme.primaryContainer;
    final bottomBarSelectedForeground = isDark ? colorScheme.onPrimary : colorScheme.onPrimaryContainer;
    final bottomBarUnselectedForeground = colorScheme.onSurfaceVariant;

    final bottomBars = [
      for (final tab in _tabs)
        switch (tab) {
          HomeTab.shop => {
              'name': context.l10n.shop,
              'icon': AppAssets.tabShop,
            },
          HomeTab.loaner => {
              'icon': AppAssets.tabLoaner,
              'name': context.l10n.loaner,
            },
          HomeTab.income => {
              'icon': AppAssets.tabIncome,
              'name': context.l10n.income,
            },
        },
    ];

    return MultiBlocListener(
      listeners: [
        BlocListener<SignoutBloc, SignoutState>(
          listener: (context, state) {
            if (state is SignoutSuccess) {
              context.read<AuthBloc>().add(AuthSignedOut());
            }
          },
        ),
        BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is Unauthenticated) {
              if (state.sessionExpired) {
                showErrorSnackBar(context, context.l10n.sessionExpired);
              } else {
                showSuccessSnackBar(context, context.l10n.signoutSuccessful);
              }
              context.goNamed(AppRoutes.signin);
            }
          },
        ),
      ],
      child: DefaultTabController(
        length: _tabs.length,
        child: Scaffold(
          extendBody: true,
          body: BottomBar(
            controller: _bottomBarController,
            // Visibility follows _onPageScroll: the bar's own scroll
            // controller is not attached to any tab's list.
            hideOnScroll: false,
            showIcon: false,
            body: (context, controller) => SafeArea(
              maintainBottomViewPadding: true,
              child: Column(
                children: [
                  ClipRect(
                    child: AnimatedAlign(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOut,
                      alignment: Alignment.bottomCenter,
                      heightFactor: _chromeVisible ? 1 : 0,
                      child: Builder(
                          builder: (context) {
                            Widget buildShopHeader({
                              bool hasFilter = false,
                              String? searchHintText,
                            }) {
                              return ShopHeader(
                                hasFilter: hasFilter,
                                searchHintText: searchHintText,
                                onSettingsPressed: _openSettingsPage,
                                onSearchChanged: _onSearchChanged,
                                onFilterPressed: _showFilterSheet,
                                searchController: _searchController,
                              );
                            }

                            return switch (_selectedTab) {
                              HomeTab.shop => BlocBuilder<ShopBloc, ShopState>(
                                builder: (context, state) {
                                  return buildShopHeader(
                                    hasFilter: state.asLoaded?.categoryFilter != null,
                                  );
                                },
                              ),
                              HomeTab.loaner => BlocBuilder<LoanerBloc, LoanerState>(
                                builder: (context, state) {
                                  return buildShopHeader(
                                    hasFilter: state.asLoaded?.hasFilter ?? false,
                                  );
                                },
                              ),
                              HomeTab.income => BlocBuilder<IncomeBloc, IncomeState>(
                                builder: (context, state) {
                                  final loaded = state.asLoaded;
                                  return buildShopHeader(
                                    hasFilter: loaded?.hasFilter ?? false,
                                    searchHintText: context.l10n.searchIncome,
                                  );
                                },
                              ),
                            };
                          },
                        ),
                    ),
                  ),
                  Expanded(
                    child: MultiBlocProvider(
                      providers: [
                        BlocProvider.value(value: context.read<LoanerBloc>()),
                        if (_isIncomeEnabled) BlocProvider.value(value: context.read<IncomeBloc>()),
                      ],
                      child: TabScrollManager(
                        controllers: _scrollControllers,
                        child: NotificationListener<ScrollUpdateNotification>(
                          onNotification: _onPageScroll,
                          child: PageView(
                            controller: _pageController,
                            physics: const NeverScrollableScrollPhysics(),
                            children: [for (final tab in _tabs) _pageFor(tab)],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            barColor: Colors.transparent,
            borderRadius: BorderRadius.circular(24),
            width: double.infinity,
            // The pill rides on the bar, whose background is transparent,
            // so it always sits just above it, whatever the safe area.
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isBackgroundSyncEnabled)
                  SyncIndicator(
                    engine: getIt<SyncEngine>(),
                    connectivity: getIt<ConnectivityService>(),
                  ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.zero,
                        decoration: BoxDecoration(
                          color: bottomBarBackground,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: colorScheme.outlineVariant),
                          boxShadow: [
                            if (!isDark)
                              BoxShadow(
                                color: colorScheme.shadow.withValues(alpha: 0.08),
                                blurRadius: 18,
                                offset: const Offset(0, 6),
                              ),
                          ],
                        ),
                        child: TabBar(
                          dividerColor: Colors.transparent,
                          indicatorSize: TabBarIndicatorSize.tab,
                          indicator: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            color: bottomBarIndicator,
                          ),
                          labelPadding: EdgeInsets.zero,
                          onTap: (index) {
                            _setChromeVisible(true);
                            _pageController.jumpToPage(index);
                            _onItemTapped(index);
                            setState(() => _selectedIndex = index);
                          },
                          splashBorderRadius: BorderRadius.circular(18),
                          tabs: List.generate(
                            bottomBars.length,
                            (index) => Tab(
                              height: 42,
                              child: _BottomBarTab(
                                iconAsset: bottomBars[index]['icon']!,
                                label: bottomBars[index]['name']!,
                                isSelected: _selectedIndex == index,
                                selectedColor: bottomBarSelectedForeground,
                                unselectedColor: bottomBarUnselectedForeground,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (bottomAction != null) ...[
                      const SizedBox(width: 8),
                      _BottomBarActionButton(
                        config: bottomAction,
                        isDark: isDark,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomActionConfig {
  const _BottomActionConfig({
    required this.tooltip,
    required this.iconAsset,
    this.onPressed,
  });

  final String tooltip;
  final String iconAsset;
  final VoidCallback? onPressed;
}

class _BottomBarTab extends StatelessWidget {
  const _BottomBarTab({
    required this.iconAsset,
    required this.label,
    required this.isSelected,
    required this.selectedColor,
    required this.unselectedColor,
  });

  final String iconAsset;
  final String label;
  final bool isSelected;
  final Color selectedColor;
  final Color unselectedColor;

  @override
  Widget build(BuildContext context) {
    final foregroundColor = isSelected ? selectedColor : unselectedColor;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            iconAsset,
            width: 24,
            height: 24,
            colorFilter: ColorFilter.mode(
              foregroundColor,
              BlendMode.srcIn,
            ),
          ),
          const SizedBox(width: 8),
          Center(
            child: isSelected
                ? Text(
                    label,
                    key: const ValueKey('selected'),
                    maxLines: 1,
                    overflow: TextOverflow.fade,
                    softWrap: false,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: foregroundColor,
                          fontWeight: FontWeight.w700,
                        ),
                  )
                : const SizedBox.shrink(key: ValueKey('unselected')),
          ),
        ],
      ),
    );
  }
}

class _BottomBarActionButton extends StatelessWidget {
  const _BottomBarActionButton({
    required this.config,
    required this.isDark,
  });

  final _BottomActionConfig config;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Tooltip(
      message: config.tooltip,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        opacity: config.onPressed == null ? 0.6 : 1,
        child: IconButton.filled(
          onPressed: config.onPressed,
          icon: SvgPicture.asset(
            config.iconAsset,
            width: 22,
            height: 22,
            colorFilter: ColorFilter.mode(
              config.onPressed == null ? colorScheme.onSurfaceVariant : colorScheme.onPrimary,
              BlendMode.srcIn,
            ),
          ),
          style: IconButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            disabledBackgroundColor: colorScheme.surfaceContainerHighest,
            disabledForegroundColor: colorScheme.onSurfaceVariant,
            elevation: isDark ? 0 : 1,
            shape: const CircleBorder(),
            minimumSize: const Size(62, 62),
            maximumSize: const Size(62, 62),
          ),
        ),
      ),
    );
  }
}
