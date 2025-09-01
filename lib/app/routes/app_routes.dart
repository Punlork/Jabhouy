import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:my_app/app/app.dart';
import 'package:my_app/auth/auth.dart';
import 'package:my_app/customer/customer.dart';
import 'package:my_app/home/home.dart';
import 'package:my_app/home/views/home_page.dart';
import 'package:my_app/loaner/loaner.dart';
import 'package:my_app/profile/profile.dart';
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
  static const formShop = 'form_shop';
  static const formLoaner = 'form_loaner';
  static const category = 'category';
  static const customer = 'customer';
  static const profile = 'profile';

  static final allowedUnauthenticated = {
    signin.toPath,
    signup.toPath,
  };

  static final allowedAuthenticated = {
    home.toPath,
    '${home.toPath}${formShop.toPath}',
    '${home.toPath}${formLoaner.toPath}',
    '${home.toPath}${category.toPath}',
    '${home.toPath}${profile.toPath}',
    '${home.toPath}${customer.toPath}',
  };

  static final GoRouter router = GoRouter(
    initialLocation: signin.toPath,
    redirect: (context, state) {
      final authState = BlocProvider.of<AuthBloc>(context).state;
      final currentPath = state.matchedLocation;

      if (authState is Unauthenticated) {
        if (!allowedUnauthenticated.contains(currentPath)) {
          return signin.toPath;
        }
      }
      if (authState is Authenticated) {
        if (!allowedAuthenticated.contains(currentPath)) {
          return home.toPath;
        }
      }
      return null;
    },
    routes: [
      GoRoute(
        path: home.toPath,
        name: home,
        pageBuilder: (BuildContext context, GoRouterState state) {
          GlobalContext.currentContext = context;
          return CustomTransitionPage(
            key: state.pageKey,
            child: MultiBlocProvider(
              providers: [
                BlocProvider(create: (context) => ShopBloc(getIt<ShopService>(), getIt<UploadBloc>())),
                BlocProvider(create: (context) => SignoutBloc(getIt<AuthService>())),
                BlocProvider(create: (context) => CategoryBloc(getIt<CategoryService>())),
                BlocProvider(create: (context) => LoanerBloc(getIt<LoanerService>())),
                BlocProvider(create: (context) => CustomerBloc(getIt<CustomerService>())),
              ],
              child: const HomePage(),
            ),
            transitionsBuilder: _rightToLeftTransition,
          );
        },
        routes: [
          GoRoute(
            path: formShop.toPath,
            name: formShop,
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
            path: formLoaner.toPath,
            name: formLoaner,
            pageBuilder: (BuildContext context, GoRouterState state) {
              GlobalContext.currentContext = context;
              final extra = state.extra! as Map<String, dynamic>;
              final existingLoaner = extra['existingLoaner'] as LoanerModel?;
              final loanerBloc = extra['loanerBloc'] as LoanerBloc;
              final customerBloc = extra['customerBloc'] as CustomerBloc;
              return CustomTransitionPage(
                key: state.pageKey,
                child: LoanerFormPage(
                  loanerBloc: loanerBloc,
                  customerBloc: customerBloc,
                  existingLoaner: existingLoaner,
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
          GoRoute(
            path: customer.toPath,
            name: customer,
            pageBuilder: (BuildContext context, GoRouterState state) {
              final extra = state.extra! as Map<String, dynamic>;
              GlobalContext.currentContext = context;
              final customer = extra['customerBloc'] as CustomerBloc;
              return CustomTransitionPage(
                key: state.pageKey,
                child: CustomerPage(customerBloc: customer),
                transitionsBuilder: _rightToLeftTransition,
              );
            },
          ),
          GoRoute(
            path: profile.toPath,
            name: profile,
            pageBuilder: (BuildContext context, GoRouterState state) {
              GlobalContext.currentContext = context;

              return CustomTransitionPage(
                key: state.pageKey,
                child: MultiBlocProvider(
                  providers: [
                    BlocProvider(
                      create: (context) => ProfileBloc(
                        getIt<UploadBloc>(),
                        getIt<ProfileService>(),
                      ),
                    ),
                  ],
                  child: const ProfilePage(),
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
