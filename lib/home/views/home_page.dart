import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
  final _isBarcodeScanEnabled =
      getIt<FeatureFlags>().isEnabled(Feature.barcodeScan);
  late final List<ScrollController> _scrollControllers;
  int _selectedIndex = 0;
  late final PageController _pageController;
  bool _hasLoadedProtectedData = false;
  final _tabs = visibleHomeTabs(getIt<FeatureFlags>());

  HomeTab get _selectedTab => _tabs[_selectedIndex];
  bool get _isIncomeEnabled => _tabs.contains(HomeTab.income);
  final _isBackgroundSyncEnabled =
      getIt<FeatureFlags>().isEnabled(Feature.backgroundSync);

  /// The search header slides away while scrolling down a list and comes
  /// back on any scroll up. Category chips live in the tab, so they stay
  /// put and move up into the header's place (decision 43).
  bool _chromeVisible = true;
  double _scrollRun = 0;
  static const _chromeScrollThreshold = 12.0;

  void _setChromeVisible(bool visible) {
    _scrollRun = 0;
    if (_chromeVisible == visible) return;
    setState(() => _chromeVisible = visible);
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

  Widget _pageFor(HomeTab tab) => switch (tab) {
        HomeTab.shop => ItemsTab(
          onEditItem: _openItemForm,
          onAddItem: (name) => _openItemForm(null, null, name),
          chromeVisible: _chromeVisible,
        ),
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
        context.read<ItemListCubit>().search(value ?? '');
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
        'customerBloc': context.read<CustomerBloc>(),
        if (_isIncomeEnabled) 'incomeBloc': context.read<IncomeBloc>(),
        'signoutBloc': context.read<SignoutBloc>(),
      },
    );
  }

  /// Adds an Item, or edits [item] (from the details sheet). A [barcode]
  /// no Item uses yet starts the new Item's first price row; a [name]
  /// (from a search) fills the new Item's name.
  void _openItemForm([Item? item, String? barcode, String? name]) {
    context.pushNamed(
      AppRoutes.formItem,
      extra: {'existingItem': item, 'barcode': barcode, 'name': name},
    );
  }

  /// Scan → the match's details, or Add item with the unknown code.
  Future<void> _scanItem() async {
    final result = await findByBarcode(
      context,
      context.read<ItemListCubit>().itemsWithBarcode,
    );
    if (!mounted) return;
    switch (result) {
      case final Item item:
        await showItemDetails(context, item, onEdit: _openItemForm);
      case final String code:
        _openItemForm(null, code);
    }
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
          label: context.l10n.itemAdd,
          onPressed: _openItemForm,
        );
      case HomeTab.loaner:
        return _BottomActionConfig(
          label: context.l10n.creditAdd,
          onPressed: _openLoanerForm,
        );
      case HomeTab.income:
        if (kReleaseMode) {
          return _BottomActionConfig(
            label: context.l10n.refreshStatus,
            onPressed: () => context.read<IncomeBloc>().add(
                  const RefreshIncomeTrackingStatus(),
                ),
          );
        }

        final isMainDevice = appState.deviceRole.isMain;
        final isBlocked =
            context.read<IncomeBloc>().state.asLoaded?.trackingStatus?.isBlockedByAnotherMainDevice ?? false;

        return _BottomActionConfig(
          label: isMainDevice ? context.l10n.addDemoData : context.l10n.mainDeviceOnly,
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
        _onAuthenticated(authState);
      }
    });
  }

  /// The app opens on Home before the session is known, so the Username
  /// gate in `authRedirect` has to be applied here once it is.
  void _onAuthenticated(Authenticated authState) {
    if (!authState.user.hasUsername) {
      context.goNamed(AppRoutes.chooseUsername);
      return;
    }
    _loadProtectedData();
  }

  void _loadProtectedData() {
    if (_hasLoadedProtectedData) return;

    _hasLoadedProtectedData = true;
    context.read<LoanerBloc>().add(LoadLoaners());
    context.read<ShopBloc>().add(ShopGetItemsEvent());
    context.read<ItemListCubit>().start();
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (previous, current) => previous.runtimeType != current.runtimeType,
      listener: (context, authState) {
        if (authState is Authenticated) {
          _onAuthenticated(authState);
          return;
        }

        if (authState is Unauthenticated) {
          context.go(AppRoutes.signin.toPath);
          _hasLoadedProtectedData = false;
          getIt<SyncCoordinator>().stop();
          context.read<ItemListCubit>().stop();
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
    final appState = context.watch<AppBloc>().state;
    final bottomAction = _buildBottomActionConfig(appState);

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
      child: Scaffold(
        // The list scrolls behind the nav bar's floating button.
        extendBody: true,
        body: SafeArea(
          bottom: false,
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
                        bool withFilter = true,
                        VoidCallback? onScanPressed,
                      }) {
                        return ShopHeader(
                          hasFilter: hasFilter,
                          searchHintText: searchHintText,
                          onSettingsPressed: _openSettingsPage,
                          onSearchChanged: _onSearchChanged,
                          onFilterPressed: withFilter ? _showFilterSheet : null,
                          onScanPressed: onScanPressed,
                          searchController: _searchController,
                        );
                      }

                      return switch (_selectedTab) {
                        // Filtering is the chips under the header.
                        HomeTab.shop => buildShopHeader(
                            searchHintText: context.l10n.itemSearchHint,
                            withFilter: false,
                            onScanPressed:
                                _isBarcodeScanEnabled ? _scanItem : null,
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
        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isBackgroundSyncEnabled)
              SyncIndicator(
                engine: getIt<SyncEngine>(),
                connectivity: getIt<ConnectivityService>(),
              ),
            AppBottomNav(
              tabs: [
                for (final tab in _tabs)
                  switch (tab) {
                    HomeTab.shop => AppNavTab(
                        icon: Icons.storefront_outlined,
                        label: context.l10n.shop,
                      ),
                    HomeTab.loaner => AppNavTab(
                        icon: Icons.menu_book_outlined,
                        label: context.l10n.credit,
                      ),
                    HomeTab.income => AppNavTab(
                        icon: Icons.account_balance_wallet_outlined,
                        label: context.l10n.income,
                      ),
                  },
              ],
              selectedIndex: _selectedIndex,
              onTabChanged: (index) {
                _setChromeVisible(true);
                _onItemTapped(index);
                setState(() => _selectedIndex = index);
              },
              actionLabel: bottomAction?.label ?? '',
              onAction: bottomAction?.onPressed,
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomActionConfig {
  const _BottomActionConfig({
    required this.label,
    this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;
}
