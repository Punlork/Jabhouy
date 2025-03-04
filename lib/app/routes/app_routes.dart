import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:my_app/app/app.dart';
import 'package:my_app/auth/auth.dart';
import 'package:my_app/home/views/views.dart';
import 'package:my_app/home/widgets/widgets.dart';

extension StringExtension on String {
  String get toPath => '/$this';
}

class GlobalContext {
  GlobalContext._();
  static BuildContext? _currentContext;

  static BuildContext get currentContext {
    if (_currentContext == null) {
      throw FlutterError('GlobalContext: _currentContext is null');
    }
    return _currentContext!;
  }

  static set currentContext(BuildContext context) {
    _currentContext = context;
  }
}

class AppRoutes {
  static const home = 'home';
  static const signin = 'signin';
  static const signup = 'signup';
  static const loading = 'loading';
  static const createShopItem = 'create_shop_item';

  static final GoRouter router = GoRouter(
    initialLocation: loading.toPath,
    redirect: (context, state) {
      final authState = BlocProvider.of<AuthBloc>(context).state;

      if (authState is AuthLoading) {
        return loading.toPath; // Show loading page during auth check
      }

      if (authState is Unauthenticated && state.matchedLocation != signin.toPath) {
        return signin.toPath;
      }
      if (authState is Authenticated && state.matchedLocation == signin.toPath) {
        return home.toPath;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: loading.toPath,
        name: loading,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const LoadingPage(),
          transitionsBuilder: _fadeTransition,
        ),
      ),
      GoRoute(
        path: home.toPath,
        name: home,
        pageBuilder: (BuildContext context, GoRouterState state) {
          GlobalContext.currentContext = context;
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
              GlobalContext.currentContext = context;
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
        path: signin.toPath,
        name: signin,
        pageBuilder: (BuildContext context, GoRouterState state) {
          GlobalContext.currentContext = context;
          return CustomTransitionPage(
            key: state.pageKey,
            child: const SigninPage(),
            transitionsBuilder: _rightToLeftTransition,
          );
        },
      ),
      GoRoute(
        path: signup.toPath,
        name: signup,
        pageBuilder: (BuildContext context, GoRouterState state) {
          GlobalContext.currentContext = context;
          return CustomTransitionPage(
            key: state.pageKey,
            child: const SignupPage(),
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
