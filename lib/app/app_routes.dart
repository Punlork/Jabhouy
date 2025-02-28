import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:my_app/auth/views/views.dart';
import 'package:my_app/home/views/views.dart';
import 'package:my_app/home/widgets/widgets.dart';

extension StringExtension on String {
  String get toPath => '/$this';
}

class AppRoutes {
  static const home = 'home';
  static const login = 'login';
  static const createShopItem = 'create_shop_item';

  static final GoRouter router = GoRouter(
    initialLocation: login.toPath,
    routes: [
      GoRoute(
        path: home.toPath,
        name: home,
        pageBuilder: (BuildContext context, GoRouterState state) {
          return CustomTransitionPage(
            key: state.pageKey,
            child: const HomePage(),
            transitionsBuilder: _rightToLeftTransition,
          );
        },
        routes: [
          GoRoute(
            path: createShopItem.toPath,
            name: createShopItem,
            pageBuilder: (BuildContext context, GoRouterState state) {
              final extra = state.extra! as Map<String, dynamic>;
              final onAdd = extra['onAdd'] as void Function(ShopItem)?;
              final existingItem = extra['existingItem'] as ShopItem?;
              return CustomTransitionPage(
                key: state.pageKey,
                child: CreateShopItemPage(
                  onSave: onAdd ?? (_) {},
                  existingItem: existingItem,
                ),
                transitionsBuilder: _rightToLeftTransition,
              );
            },
          ),
        ],
      ),
      GoRoute(
        path: login.toPath,
        name: login,
        pageBuilder: (BuildContext context, GoRouterState state) {
          return CustomTransitionPage(
            key: state.pageKey,
            child: const LoginPage(),
            transitionsBuilder: _rightToLeftTransition,
          );
        },
      ),
    ],
  );

  static Widget _fadeTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(opacity: animation, child: child);
  }

  static Widget _rightToLeftTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    const begin = Offset(1, 0);
    const end = Offset.zero;
    const curve = Curves.easeInOut;

    final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
    final offsetAnimation = animation.drive(tween);

    return SlideTransition(position: offsetAnimation, child: child);
  }
}
