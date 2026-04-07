import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:go_router/go_router.dart';
import 'package:my_app/app/app.dart';
import 'package:my_app/auth/auth.dart';
import 'package:my_app/customer/customer.dart';
import 'package:my_app/income/income.dart';
import 'package:my_app/l10n/l10n.dart';
import 'package:my_app/loaner/loaner.dart';
import 'package:my_app/shop/shop.dart';

class TabScrollManager extends InheritedWidget {
  const TabScrollManager({
    required this.controllers,
    required super.child,
    super.key,
  });

  final List<ScrollController> controllers;

  static TabScrollManager? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<TabScrollManager>();
  }

  @override
  bool updateShouldNotify(TabScrollManager oldWidget) {
    return controllers != oldWidget.controllers;
  }

  ScrollController getController(int index) => controllers[index];
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  late final List<ScrollController> _scrollControllers;
  int _selectedIndex = 0;
  late final PageController _pageController;
  bool _hasLoadedProtectedData = false;

  static const _pages = [
    ShopTab(),
    LoanerView(),
    IncomeView(),
  ];

  void _onItemTapped(int index) {
    if (index == _selectedIndex) {
      final controller = _scrollControllers[index];
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
    switch (_selectedIndex) {
      case 0:
        context.read<ShopBloc>().add(
              ShopGetItemsEvent(
                searchQuery: value,
                categoryFilter:
                    context.read<ShopBloc>().state.asLoaded?.categoryFilter,
              ),
            );
      case 1:
        context.read<LoanerBloc>().add(LoadLoaners(searchQuery: value));
      case 2:
        context.read<IncomeBloc>().add(LoadIncomeDashboard(searchQuery: value));
    }
  }

  void _showFilterSheet() {
    switch (_selectedIndex) {
      case 0:
        showModalBottomSheet<void>(
          context: context,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          builder: (_) => MultiBlocProvider(
            providers: [
              BlocProvider.value(value: context.read<CategoryBloc>()),
              BlocProvider.value(value: context.read<ShopBloc>()),
            ],
            child: FilterSheet(
              initialCategoryFilter:
                  context.read<ShopBloc>().state.asLoaded?.categoryFilter,
              onApply: (category) => context.read<ShopBloc>().add(
                    ShopGetItemsEvent(categoryFilter: category),
                  ),
            ),
          ),
        );
      case 1:
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
                initialFromDate:
                    context.read<LoanerBloc>().state.asLoaded?.fromDate,
                initialToDate:
                    context.read<LoanerBloc>().state.asLoaded?.toDate,
                initialLoanerFilter:
                    context.read<LoanerBloc>().state.asLoaded?.loanerFilter,
                onApply: (fromDate, toDate, loanerFilter) =>
                    context.read<LoanerBloc>().add(
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
      case 2:
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
                initialFromDate:
                    context.read<IncomeBloc>().state.asLoaded?.fromDate,
                initialToDate:
                    context.read<IncomeBloc>().state.asLoaded?.toDate,
                initialBankFilter:
                    context.read<IncomeBloc>().state.asLoaded?.bankFilter,
                initialRecordFilter:
                    context.read<IncomeBloc>().state.asLoaded?.recordFilter ??
                        NotificationRecordFilter.all,
                onApply: (fromDate, toDate, bankFilter, recordFilter) =>
                    context.read<IncomeBloc>().add(
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

  void _showSettingsSheet(VoidCallback onSignout) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: context.read<CategoryBloc>()),
          BlocProvider.value(value: context.read<ShopBloc>()),
          BlocProvider.value(value: context.read<CustomerBloc>()),
        ],
        child: SettingsSheet(onSignout: onSignout),
      ),
    );
  }

  void _openShopForm() {
    context.pushNamed(
      AppRoutes.formShop,
      extra: {
        'shop': context.read<ShopBloc>(),
        'category': context.read<CategoryBloc>(),
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

    final trackingStatus =
        context.read<IncomeBloc>().state.asLoaded?.trackingStatus;
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
    switch (_selectedIndex) {
      case 0:
        return _BottomActionConfig(
          label: context.l10n.addItem,
          icon: Icons.add_business_rounded,
          onPressed: _openShopForm,
        );
      case 1:
        return _BottomActionConfig(
          label: context.l10n.addLoaner,
          icon: Icons.person_add_alt_1_rounded,
          onPressed: _openLoanerForm,
        );
      case 2:
        if (kReleaseMode) return null;

        final isMainDevice = appState.deviceRole.isMain;
        final isBlocked = context
                .read<IncomeBloc>()
                .state
                .asLoaded
                ?.trackingStatus
                ?.isBlockedByAnotherMainDevice ??
            false;

        return _BottomActionConfig(
          label: isMainDevice
              ? context.l10n.addDemoData
              : context.l10n.mainDeviceOnly,
          icon: Icons.bolt_rounded,
          onPressed: isMainDevice && !isBlocked
              ? () => _seedIncomeDemoData(appState)
              : null,
        );
    }

    return null;
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
    _scrollControllers = [
      ScrollController(),
      ScrollController(),
      ScrollController(),
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
    context.read<IncomeBloc>().add(const RefreshIncomeTrackingStatus());
  }

  @override
  void dispose() {
    for (final controller in _scrollControllers) {
      controller.dispose();
    }
    _pageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (previous, current) =>
          previous.runtimeType != current.runtimeType,
      listener: (context, authState) {
        if (authState is Authenticated) {
          _loadProtectedData();
          return;
        }

        // redirect to splash screen to trigger auth check and data reload
        context.go(AppRoutes.signin.toPath);
        _hasLoadedProtectedData = false;
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
    final bottomBarBackground =
        isDark ? colorScheme.surfaceContainerLow : colorScheme.surface;
    final bottomBarIndicator =
        isDark ? colorScheme.primary : colorScheme.primaryContainer;
    final bottomBarSelectedForeground =
        isDark ? colorScheme.onPrimary : colorScheme.onPrimaryContainer;
    final bottomBarUnselectedForeground = colorScheme.onSurfaceVariant;

    final bottomBars = [
      {
        'name': context.l10n.shop,
        'icon': Icons.store_rounded,
      },
      {
        'icon': Icons.handshake_rounded,
        'name': context.l10n.loaner,
      },
      {
        'icon': Icons.pie_chart_rounded,
        'name': context.l10n.income,
      },
    ];

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        extendBody: true,
        body: BottomBar(
          body: (context, controller) => SafeArea(
            maintainBottomViewPadding: true,
            child: Column(
              children: [
                Builder(
                  builder: (context) {
                    Widget buildShopHeader({
                      bool hasFilter = false,
                      String? searchHintText,
                    }) {
                      return ShopHeader(
                        hasFilter: hasFilter,
                        searchHintText: searchHintText,
                        onSettingsPressed: () => _showSettingsSheet(
                          () => context
                              .read<SignoutBloc>()
                              .add(const SignoutSubmitted()),
                        ),
                        onSearchChanged: _onSearchChanged,
                        onFilterPressed: _showFilterSheet,
                        searchController: _searchController,
                      );
                    }

                    final blocBuilders = {
                      0: BlocBuilder<ShopBloc, ShopState>(
                        builder: (context, state) {
                          return buildShopHeader(
                            hasFilter: state.asLoaded?.categoryFilter != null,
                          );
                        },
                      ),
                      1: BlocBuilder<LoanerBloc, LoanerState>(
                        builder: (context, state) {
                          return buildShopHeader(
                            hasFilter: state.asLoaded?.hasFilter ?? false,
                          );
                        },
                      ),
                      2: BlocBuilder<IncomeBloc, IncomeState>(
                        builder: (context, state) {
                          final loaded = state.asLoaded;
                          return buildShopHeader(
                            hasFilter: loaded?.hasFilter ?? false,
                            searchHintText: context.l10n.searchIncome,
                          );
                        },
                      ),
                    };

                    return blocBuilders[_selectedIndex] ?? buildShopHeader();
                  },
                ),
                Expanded(
                  child: MultiBlocProvider(
                    providers: [
                      BlocProvider.value(value: context.read<LoanerBloc>()),
                      BlocProvider.value(value: context.read<IncomeBloc>()),
                    ],
                    child: TabScrollManager(
                      controllers: _scrollControllers,
                      child: PageView(
                        controller: _pageController,
                        physics: const NeverScrollableScrollPhysics(),
                        children: _pages,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          barColor: bottomBarBackground,
          borderRadius: BorderRadius.circular(24),
          width: double.infinity,
          child: Container(
            padding: const EdgeInsets.all(8),
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
            child: Row(
              children: [
                Expanded(
                  child: TabBar(
                    dividerColor: Colors.transparent,
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicator: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      color: bottomBarIndicator,
                    ),
                    labelPadding: EdgeInsets.zero,
                    onTap: (index) {
                      _pageController.jumpToPage(index);
                      _onItemTapped(index);
                      setState(() => _selectedIndex = index);
                    },
                    splashBorderRadius: BorderRadius.circular(18),
                    tabs: List.generate(
                      bottomBars.length,
                      (index) => Tab(
                        height: 52,
                        child: _BottomBarTab(
                          icon: bottomBars[index]['icon']! as IconData,
                          label: bottomBars[index]['name']! as String,
                          isSelected: _selectedIndex == index,
                          selectedColor: bottomBarSelectedForeground,
                          unselectedColor: bottomBarUnselectedForeground,
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
          ),
        ),
      ),
    );
  }
}

class _BottomActionConfig {
  const _BottomActionConfig({
    required this.label,
    required this.icon,
    this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
}

class _BottomBarTab extends StatelessWidget {
  const _BottomBarTab({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.selectedColor,
    required this.unselectedColor,
  });

  final IconData icon;
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 22, color: foregroundColor),
          // AnimatedSize(
          //   duration: const Duration(milliseconds: 180),
          //   curve: Curves.easeOut,
          //   child: isSelected
          //       ? Padding(
          //           padding: const EdgeInsets.only(left: 8),
          //           child: Text(
          //             label,
          //             maxLines: 1,
          //             overflow: TextOverflow.fade,
          //             softWrap: false,
          //             style: Theme.of(context).textTheme.labelLarge?.copyWith(
          //                   color: foregroundColor,
          //                   fontWeight: FontWeight.w700,
          //                 ),
          //           ),
          //         )
          //       : const SizedBox.shrink(),
          // ),
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

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 180),
      opacity: config.onPressed == null ? 0.6 : 1,
      child: FilledButton.icon(
        onPressed: config.onPressed,
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          disabledBackgroundColor: colorScheme.surfaceContainerHighest,
          disabledForegroundColor: colorScheme.onSurfaceVariant,
          elevation: isDark ? 0 : 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        icon: Icon(config.icon, size: 18),
        label: Text(
          config.label,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
