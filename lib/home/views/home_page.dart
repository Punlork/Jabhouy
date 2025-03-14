import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:my_app/app/app.dart';
import 'package:my_app/auth/auth.dart';
import 'package:my_app/loaner/loaner.dart';
import 'package:my_app/shop/shop.dart';

class ScrollControllerManager extends InheritedWidget {
  const ScrollControllerManager({
    required this.controllers,
    required super.child,
    super.key,
  });

  final List<ScrollController> controllers;

  static ScrollControllerManager? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ScrollControllerManager>();
  }

  @override
  bool updateShouldNotify(ScrollControllerManager oldWidget) {
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
  int _selectedIndex = 0;
  final _searchController = TextEditingController();
  late final AnimationController _animationController;
  late final List<ScrollController> _scrollControllers;

  static const List<Widget> _pages = <Widget>[
    ShopTab(),
    LoanerView(),
  ];

  void _onItemTapped(int index) {
    if (_selectedIndex == index) {
      // _animationController.();
      final controller = _scrollControllers[index];
      if (controller.hasClients) {
        controller.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
      setState(() {});
    } else {
      _selectedIndex = index;
      setState(() {});
    }
  }

  void _onSearchChanged(String? value) {
    context.read<ShopBloc>().add(ShopGetItemsEvent(searchQuery: value));
  }

  void _showFilterSheet() {
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
  }

  void _showSettingsSheet(VoidCallback onSignout) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: context.read<CategoryBloc>()),
          BlocProvider.value(value: context.read<ShopBloc>()),
        ],
        child: SettingsSheet(onSignout: onSignout),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scrollControllers = [
      ScrollController(),
      ScrollController(),
    ];
    context.read<LoanerBloc>().add(LoadLoaners());
    context.read<ShopBloc>().add(ShopGetItemsEvent());
    context.read<CategoryBloc>().add(CategoryGetEvent());
  }

  @override
  void dispose() {
    for (final controller in _scrollControllers) {
      controller.dispose();
    }
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final iconList = <IconData>[
      Icons.store_rounded,
      Icons.handshake_rounded,
    ];
    final statusBarHeight = MediaQuery.of(context).viewPadding.top;
    final viewPaddingBottom = MediaQuery.paddingOf(context).bottom;

    return ScrollControllerManager(
      controllers: _scrollControllers,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        extendBody: true,
        body: SafeArea(
          top: false,
          bottom: false,
          child: Column(
            children: [
              Container(
                height: statusBarHeight,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.primary,
                      colorScheme.primaryContainer,
                    ],
                  ),
                ),
              ),
              ShopHeader(
                onSettingsPressed: () => _showSettingsSheet(
                  () => context.read<SignoutBloc>().add(const SignoutSubmitted()),
                ),
                onSearchChanged: _onSearchChanged,
                onFilterPressed: _showFilterSheet,
                searchController: _searchController,
              ),
              Expanded(
                child: MultiBlocProvider(
                  providers: [
                    BlocProvider.value(value: context.read<LoanerBloc>()),
                  ],
                  child: _pages[_selectedIndex],
                ),
              ),
              Container(
                height: viewPaddingBottom + 15,
                color: Colors.black,
              ),
            ],
          ),
        ),
        floatingActionButton: SizedBox(
          height: 64,
          width: 64,
          child: FloatingActionButton(
            onPressed: () {
              if (_selectedIndex == 0) {
                context.pushNamed(
                  AppRoutes.createShopItem,
                  extra: {
                    'shop': context.read<ShopBloc>(),
                    'category': context.read<CategoryBloc>(),
                    'onAdd': (ShopItemModel item) {},
                  },
                );
              } else if (_selectedIndex == 1) {
                showAddLoanerDialog(
                  context,
                  context.read<LoanerBloc>(),
                );
              }
            },
            backgroundColor: colorScheme.primary,
            
            foregroundColor: colorScheme.onPrimaryContainer,
            elevation: 6,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16), // Changed from CircleBorder for a fresh look
            ),
            child: const Icon(
              Icons.add,
              size: 28,
              color: Colors.white,
            ),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
        bottomNavigationBar: AnimatedBottomNavigationBar.builder(
          height: 72,
          itemCount: iconList.length,
          tabBuilder: (int index, bool isActive) => Icon(
            iconList[index],
            size: 26,
            color: isActive ? colorScheme.primary : colorScheme.onSurface.withValues(alpha: .6),
          ),
          activeIndex: _selectedIndex,
          onTap: _onItemTapped,
          gapLocation: GapLocation.end,
          notchSmoothness: NotchSmoothness.defaultEdge,
          notchMargin: 20,
          leftCornerRadius: 16,
          backgroundColor: colorScheme.surface,
          splashColor: colorScheme.primary.withValues(alpha: .3),
          splashRadius: 30,
          shadow: BoxShadow(
            offset: const Offset(0, 1),
            blurRadius: 12,
            spreadRadius: 0.5,
            color: Colors.black.withValues(alpha: .1),
          ),
        ),
      ),
    );
  }
}
