// ignore_for_file: inference_failure_on_instance_creation

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_runtime_debugger/flutter_runtime_debugger.dart';
import 'package:go_router/go_router.dart';
import 'package:jabhouy/app/app.dart';
import 'package:jabhouy/auth/auth.dart';
import 'package:jabhouy/customer/customer.dart';
import 'package:jabhouy/home/home.dart';
import 'package:jabhouy/home/views/home_page.dart';
import 'package:jabhouy/income/income.dart';
import 'package:jabhouy/loaner/loaner.dart';
import 'package:jabhouy/profile/profile.dart';
import 'package:jabhouy/settings/settings.dart';
import 'package:jabhouy_core/jabhouy_core.dart';
import 'package:jabhouy_net/jabhouy_net.dart';
import 'package:jabhouy_shop/jabhouy_shop.dart';
import 'package:jabhouy_ui/jabhouy_ui.dart';

/// The router itself, and the two sets its redirect consults.
///
/// The route *names* live in `jabhouy_core` as [AppRoutes], because a
/// feature package needs them and this file imports every feature. What
/// stays here is the wiring, which is the app shell's job by definition.
class AppRouter {
  const AppRouter._();

  static final allowedUnauthenticated = {
    AppRoutes.signin.toPath,
    AppRoutes.signup.toPath,
  };

  static final allowedAuthenticated = {
    AppRoutes.home.toPath,
    '${AppRoutes.home.toPath}${AppRoutes.formShop.toPath}',
    '${AppRoutes.home.toPath}${AppRoutes.formLoaner.toPath}',
    '${AppRoutes.home.toPath}${AppRoutes.category.toPath}',
    '${AppRoutes.home.toPath}${AppRoutes.profile.toPath}',
    '${AppRoutes.home.toPath}${AppRoutes.settings.toPath}',
    if (_isDiagnosticsEnabled) '${AppRoutes.home.toPath}${AppRoutes.appDiagnostics.toPath}',
    '${AppRoutes.home.toPath}${AppRoutes.customer.toPath}',
    // Left out when income is off, so the redirect below sends a stale
    // link home instead of to a page with no bloc.
    if (_isIncomeEnabled && _isDiagnosticsEnabled)
      '${AppRoutes.home.toPath}${AppRoutes.incomeDiagnostics.toPath}',
  };

  static bool get _isIncomeEnabled => getIt<FeatureFlags>().isEnabled(Feature.income);
  static bool get _isDiagnosticsEnabled => getIt<FeatureFlags>().isEnabled(Feature.diagnostics);

  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.home.toPath,
    observers: [DebuggerRouteObserver()],
    redirect: (context, state) {
      final authState = BlocProvider.of<AuthBloc>(context).state;
      final currentPath = state.matchedLocation;

      if (authState is Unauthenticated) {
        if (!allowedUnauthenticated.contains(currentPath)) {
          return AppRoutes.signin.toPath;
        }
      }
      if (authState is Authenticated) {
        if (!allowedAuthenticated.contains(currentPath)) {
          return AppRoutes.home.toPath;
        }
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.home.toPath,
        name: AppRoutes.home,
        pageBuilder: (BuildContext context, GoRouterState state) {
          GlobalContext.currentContext = context;
          return CustomTransitionPage(
            key: state.pageKey,
            child: MultiBlocProvider(
              providers: [
                BlocProvider(
                  create: (context) => ShopBloc(
                    getIt<ShopRepository>(),
                    getIt<UploadBloc>(),
                    getIt<ConnectivityService>(),
                    flags: getIt<FeatureFlags>(),
                  ),
                ),
                BlocProvider(
                  create: (context) => SignoutBloc(getIt<AuthService>()),
                ),
                BlocProvider(
                  create: (context) => CategoryBloc(
                    getIt<CategoryRepository>(),
                    flags: getIt<FeatureFlags>(),
                  ),
                ),
                BlocProvider(
                  create: (context) => LoanerBloc(
                    getIt<LoanerRepository>(),
                    getIt<RefreshLoanersUseCase>(),
                    getIt<ConnectivityService>(),
                    flags: getIt<FeatureFlags>(),
                  ),
                ),
                BlocProvider(
                  create: (context) => CustomerBloc(
                    getIt<CustomerRepository>(),
                    getIt<ConnectivityService>(),
                    flags: getIt<FeatureFlags>(),
                  ),
                ),
                // No bloc, no capture: IncomeBloc is the only caller of
                // IncomeService.initialize, which starts the listener.
                if (_isIncomeEnabled)
                  BlocProvider(
                    create: (context) => IncomeBloc(
                      getIt<IncomeService>(),
                      getIt<FcmService>(),
                    ),
                  ),
              ],
              child: const HomePage(),
            ),
            transitionsBuilder: _rightToLeftTransition,
          );
        },
        routes: [
          GoRoute(
            path: AppRoutes.formShop.toPath,
            name: AppRoutes.formShop,
            pageBuilder: (BuildContext context, GoRouterState state) {
              GlobalContext.currentContext = context;
              final extra = state.extra! as Map<String, dynamic>;
              final onAdd = extra['onAdd'] as void Function(ShopItemModel)?;
              final existingItem = extra['existingItem'] as ShopItemModel?;
              final activeCategory = extra['activeCategory'] as CategoryItemModel?;
              final shop = extra['shop'] as ShopBloc;
              final category = extra['category'] as CategoryBloc;
              return CustomTransitionPage(
                key: state.pageKey,
                child: ShopItemFormPage(
                  onSaved: onAdd ?? (_) {},
                  existingItem: existingItem,
                  activeCategory: activeCategory,
                  shop: shop,
                  category: category,
                ),
                transitionsBuilder: _rightToLeftTransition,
              );
            },
          ),
          GoRoute(
            path: AppRoutes.formLoaner.toPath,
            name: AppRoutes.formLoaner,
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
            path: AppRoutes.category.toPath,
            name: AppRoutes.category,
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
            path: AppRoutes.customer.toPath,
            name: AppRoutes.customer,
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
            path: AppRoutes.profile.toPath,
            name: AppRoutes.profile,
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
          GoRoute(
            path: AppRoutes.settings.toPath,
            name: AppRoutes.settings,
            pageBuilder: (BuildContext context, GoRouterState state) {
              final extra = state.extra as Map<String, dynamic>?;
              final categoryBloc = extra?['category'] as CategoryBloc? ?? context.read<CategoryBloc>();
              final shopBloc = extra?['shop'] as ShopBloc? ?? context.read<ShopBloc>();
              final customerBloc = extra?['customerBloc'] as CustomerBloc? ?? context.read<CustomerBloc>();
              final incomeBloc = extra?['incomeBloc'] as IncomeBloc? ?? _maybeReadIncomeBloc(context);
              final signoutBloc = extra?['signoutBloc'] as SignoutBloc? ?? context.read<SignoutBloc>();
              GlobalContext.currentContext = context;

              return CustomTransitionPage(
                key: state.pageKey,
                child: MultiBlocProvider(
                  providers: [
                    BlocProvider.value(value: categoryBloc),
                    BlocProvider.value(value: shopBloc),
                    BlocProvider.value(value: customerBloc),
                    if (incomeBloc != null) BlocProvider.value(value: incomeBloc),
                    BlocProvider.value(value: signoutBloc),
                  ],
                  child: const SettingsPage(),
                ),
                transitionsBuilder: _rightToLeftTransition,
              );
            },
          ),
          GoRoute(
            path: AppRoutes.appDiagnostics.toPath,
            name: AppRoutes.appDiagnostics,
            pageBuilder: (BuildContext context, GoRouterState state) {
              final extra = state.extra as Map<String, dynamic>?;
              final incomeBloc = extra?['incomeBloc'] as IncomeBloc? ?? _maybeReadIncomeBloc(context);
              GlobalContext.currentContext = context;

              return CustomTransitionPage(
                key: state.pageKey,
                child: incomeBloc == null
                    ? const AppDiagnosticsPage()
                    : BlocProvider.value(
                        value: incomeBloc,
                        child: const AppDiagnosticsPage(),
                      ),
                transitionsBuilder: _rightToLeftTransition,
              );
            },
          ),
          GoRoute(
            path: AppRoutes.incomeDiagnostics.toPath,
            name: AppRoutes.incomeDiagnostics,
            pageBuilder: (BuildContext context, GoRouterState state) {
              final extra = state.extra as Map<String, dynamic>?;
              final incomeBloc = extra?['incomeBloc'] as IncomeBloc? ?? BlocProvider.of<IncomeBloc>(context);
              GlobalContext.currentContext = context;

              return CustomTransitionPage(
                key: state.pageKey,
                child: BlocProvider.value(
                  value: incomeBloc,
                  child: const IncomeDiagnosticsPage(),
                ),
                transitionsBuilder: _rightToLeftTransition,
              );
            },
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.signin.toPath,
        name: AppRoutes.signin,
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
        path: AppRoutes.signup.toPath,
        name: AppRoutes.signup,
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

  /// Null when income is off, or when a page is opened without it above.
  static IncomeBloc? _maybeReadIncomeBloc(BuildContext context) {
    try {
      return context.read<IncomeBloc>();
    } on ProviderNotFoundException {
      return null;
    }
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
