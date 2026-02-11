import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:go_router/go_router.dart';
import 'package:my_app/app/app.dart';
import 'package:my_app/auth/auth.dart';
import 'package:my_app/customer/customer.dart';
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

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  late final List<ScrollController> _scrollControllers;
  int _selectedIndex = 0;
  late final PageController _pageController;

  static const _pages = [
    ShopTab(),
    LoanerView(),
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
                categoryFilter: context.read<ShopBloc>().state.asLoaded?.categoryFilter,
              ),
            );
      case 1:
        context.read<LoanerBloc>().add(LoadLoaners(searchQuery: value));
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
              initialCategoryFilter: context.read<ShopBloc>().state.asLoaded?.categoryFilter,
              onApply: (category) => context.read<ShopBloc>().add(ShopGetItemsEvent(categoryFilter: category)),
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
    }
  }

  void _showSettingsSheet(VoidCallback onSignout) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
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

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
    _scrollControllers = [
      ScrollController(),
      ScrollController(),
    ];
    context.read<LoanerBloc>().add(LoadLoaners());
    context.read<ShopBloc>().add(ShopGetItemsEvent());
    context.read<CategoryBloc>().add(CategoryGetEvent());
    context.read<CustomerBloc>().add(LoadCustomers());
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
    final colorScheme = Theme.of(context).colorScheme;

    final statusBarHeight = MediaQuery.of(context).viewPadding.top;
    // final isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    final bottomBars = <Map<String, dynamic>>[
      {
        'name': context.l10n.shop,
        'icon': Icons.store_rounded,
      },
      {
        'icon': Icons.handshake_rounded,
        'name': context.l10n.loaner,
      },
    ];

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        extendBody: true,
        backgroundColor: Colors.white,
        body: BottomBar(
          body: (context, controller) => SafeArea(
            top: false,
            maintainBottomViewPadding: true,
            child: Column(
              children: [
                Column(
                  children: <Widget>[
                    Container(
                      height: statusBarHeight,
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                      ),
                    ),
                    Builder(
                      builder: (context) {
                        Widget buildShopHeader({bool hasFilter = false}) {
                          return ShopHeader(
                            hasFilter: hasFilter,
                            onSettingsPressed: () => _showSettingsSheet(
                              () => context.read<SignoutBloc>().add(const SignoutSubmitted()),
                            ),
                            onSearchChanged: _onSearchChanged,
                            onFilterPressed: _showFilterSheet,
                            searchController: _searchController,
                          );
                        }

                        final blocBuilders = {
                          0: BlocBuilder<ShopBloc, ShopState>(
                            builder: (context, state) {
                              return buildShopHeader(hasFilter: state.asLoaded?.categoryFilter != null);
                            },
                          ),
                          1: BlocBuilder<LoanerBloc, LoanerState>(
                            builder: (context, state) {
                              return buildShopHeader(hasFilter: state.asLoaded?.hasFilter ?? false);
                            },
                          ),
                        };

                        return blocBuilders[_selectedIndex] ?? buildShopHeader();
                      },
                    ),
                  ],
                ),
                Expanded(
                  child: MultiBlocProvider(
                    providers: [
                      BlocProvider.value(value: context.read<LoanerBloc>()),
                    ],
                    child: PageView(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      children: _pages,
                    ),
                  ),
                ),
              ],
            ),
          ),
          barColor: colorScheme.primary.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(16),
          offset: 4,
          child: TabBar(
            dividerColor: Colors.transparent,
            indicatorSize: TabBarIndicatorSize.tab,
            indicator: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: colorScheme.onPrimaryContainer,
            ),
            onTap: (index) {
              _pageController.jumpToPage(index);
              _onItemTapped(index);
              setState(() => _selectedIndex = index);
            },
            tabs: List.generate(
              bottomBars.length,
              (index) => Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    Icon(
                      bottomBars[index]['icon'] as IconData,
                      size: 26,
                      color: _selectedIndex == index ? Colors.white : Colors.grey,
                    ),

                    Opacity(
                      opacity: _selectedIndex == index ? 1.0 : 0.0,
                      child: Text(
                        bottomBars[index]['name'] as String,
                        style: TextStyle(
                          color: _selectedIndex == index ? Colors.white : Colors.grey,
                          fontSize: 16,
                          fontWeight: _selectedIndex == index ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ),
                    // if (_selectedIndex == index) ...[
                    // ],
                  ],
                ),
              ),
            ),
          ),
        ),
        floatingActionButtonAnimator: FloatingActionButtonAnimator.scaling,
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 60),
          child: SizedBox(
            height: 42,
            width: 120,
            child: FloatingActionButton(
              onPressed: () {
                switch (_selectedIndex) {
                  case 0:
                    context.pushNamed(
                      AppRoutes.formShop,
                      extra: {
                        'shop': context.read<ShopBloc>(),
                        'category': context.read<CategoryBloc>(),
                        'onAdd': (ShopItemModel item) {},
                      },
                    );
                  case 1:
                    context.pushNamed(
                      AppRoutes.formLoaner,
                      extra: {
                        'loanerBloc': context.read<LoanerBloc>(),
                        'customerBloc': context.read<CustomerBloc>(),
                      },
                    );
                }
              },
              backgroundColor: colorScheme.primary.withValues(alpha: 0.8),
              foregroundColor: colorScheme.onPrimaryContainer,
              elevation: 6,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                  topRight: Radius.circular(4),
                  bottomLeft: Radius.circular(4),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..scale(-1.0, 1),
                    child: const Icon(
                      Icons.add_comment_rounded,
                      size: 24,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _selectedIndex == 0 ? context.l10n.addItem : context.l10n.addLoaner,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        persistentFooterAlignment: AlignmentDirectional.topEnd,
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      ),
    );
  }
}
