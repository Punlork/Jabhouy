import 'dart:ui';

import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:my_app/app/app.dart';
import 'package:my_app/auth/auth.dart';
import 'package:my_app/loaner/loaner.dart';
import 'package:my_app/shop/shop.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  final _searchController = TextEditingController();

  static const List<Widget> _pages = <Widget>[
    ShopTab(),
    LoanerView(),
  ];

  void _onItemTapped(int index) {
    if (_selectedIndex != index) {
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
    context.read<LoanerBloc>().add(LoadLoaners());
    context.read<ShopBloc>().add(ShopGetItemsEvent());
    context.read<CategoryBloc>().add(CategoryGetEvent());
  }

  @override
  void dispose() {
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

    return Scaffold(
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
        height: 72,
        width: 72,
        child: FittedBox(
          child: FloatingActionButton(
            onPressed: () {
              if (_selectedIndex == 0) {
                // ShopTab: Add shop item
                context.pushNamed(
                  AppRoutes.createShopItem,
                  extra: {
                    'shop': context.read<ShopBloc>(),
                    'category': context.read<CategoryBloc>(),
                    'onAdd': (ShopItemModel item) {
                      // Handler for adding item
                    },
                  },
                );
              } else if (_selectedIndex == 1) {
                showAddLoanerDialog(
                  context,
                  context.read<LoanerBloc>(),
                );
              }
            },
            backgroundColor: colorScheme.primaryContainer,
            foregroundColor: colorScheme.onPrimaryContainer,
            elevation: 10,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(100),
            ),
            child: const Icon(
              Icons.add,
            ),
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
        notchMargin: 16,
        leftCornerRadius: 16,
        backgroundColor: colorScheme.surface,
        splashColor: colorScheme.primary.withValues(alpha: .1),
        shadow: BoxShadow(
          offset: const Offset(0, 1),
          blurRadius: 12,
          spreadRadius: 0.5,
          color: Colors.black.withValues(alpha: .1),
        ),
      ),
    );
  }
}
