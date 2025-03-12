import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:my_app/app/app.dart';
import 'package:my_app/shop/shop.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;

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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final iconList = <IconData>[
      Icons.store_rounded,
      Icons.handshake_rounded,
    ];

    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              colorScheme.primary,
              colorScheme.primaryContainer,
            ],
            stops: const [0.0, 0.7],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: _pages[_selectedIndex],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
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
        },
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
        elevation: 10,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(100),
        ),
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
      bottomNavigationBar: AnimatedBottomNavigationBar.builder(
        itemCount: iconList.length,
        tabBuilder: (int index, bool isActive) => Icon(
          iconList[index],
          size: 24,
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

class LoanerView extends StatelessWidget {
  const LoanerView({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white,
      child: Center(
        child: Text(
          'Coming Soon',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
    );
  }
}
