import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:my_app/app/app.dart';
import 'package:my_app/auth/auth.dart';
import 'package:my_app/home/home.dart';
import 'package:my_app/home/views/home_page.dart';
import 'package:my_app/loaner/bloc/loaner_bloc.dart';
import 'package:my_app/shop/shop.dart';

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
  static const category = 'category';

  static final allowedUnauthenticated = {
    signin.toPath,
    signup.toPath,
    loading.toPath,
  };

  static final allowedAuthenticated = {
    home.toPath,
    '${home.toPath}${createShopItem.toPath}',
    '${home.toPath}${category.toPath}',
    loading.toPath,
  };

  static final GoRouter router = GoRouter(
    initialLocation: loading.toPath,
    redirect: (context, state) {
      final authState = BlocProvider.of<AuthBloc>(context).state;
      final currentPath = state.matchedLocation;

      if (authState is AuthLoading) {
        return loading.toPath;
      }

      if (authState is Unauthenticated) {
        if (!allowedUnauthenticated.contains(currentPath)) {
          return signin.toPath;
        }
      }
      if (authState is Authenticated && state.matchedLocation == signin.toPath) {
        if (!allowedAuthenticated.contains(currentPath)) {
          return home.toPath;
        }
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
            child: MultiBlocProvider(
              providers: [
                BlocProvider(
                  create: (context) => ShopBloc(
                    getIt<ShopService>(),
                    getIt<UploadBloc>(),
                  ),
                ),
                BlocProvider(
                  create: (context) => SignoutBloc(getIt<AuthService>()),
                ),
                BlocProvider(
                  create: (context) => CategoryBloc(getIt<CategoryService>()),
                ),
                BlocProvider(
                  create: (context) => LoanerBloc(),
                ),
              ],
              child: const HomePage(),
            ),
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
              final onAdd = extra['onAdd'] as void Function(ShopItemModel)?;
              final existingItem = extra['existingItem'] as ShopItemModel?;
              final shop = extra['shop'] as ShopBloc;
              final category = extra['category'] as CategoryBloc;
              return CustomTransitionPage(
                key: state.pageKey,
                child: ShopItemFormPage(
                  onSaved: onAdd ?? (_) {},
                  existingItem: existingItem,
                  shop: shop,
                  category: category,
                ),
                transitionsBuilder: _rightToLeftTransition,
              );
            },
          ),
          GoRoute(
            path: category.toPath,
            name: category,
            pageBuilder: (BuildContext context, GoRouterState state) {
              final extra = state.extra! as Map<String, dynamic>;
              GlobalContext.currentContext = context;
              final category = extra['category'] as CategoryBloc;
              final shop = extra['shop'] as ShopBloc;
              return CustomTransitionPage(
                key: state.pageKey,
                child: CategoryPage(
                  category: category,
                  shop: shop,
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
