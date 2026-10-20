// ignore_for_file: inference_failure_on_instance_creation

import 'dart:async';

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
import 'package:jabhouy/membership/membership.dart';
import 'package:jabhouy/profile/profile.dart';
import 'package:jabhouy/settings/settings.dart';
import 'package:jabhouy_core/jabhouy_core.dart';
import 'package:jabhouy_net/jabhouy_net.dart';
import 'package:jabhouy_shop/jabhouy_shop.dart';
import 'package:jabhouy_ui/jabhouy_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The router itself; its redirect rules live in [authRedirect].
///
/// The route *names* live in `jabhouy_core` as [AppRoutes], because a
/// feature package needs them and this file imports every feature. What
/// stays here is the wiring, which is the app shell's job by definition.
class AppRouter {
  const AppRouter._();

  /// Home's list-or-grid choice, remembered on the phone.
  static const _itemGridKey = 'item_list_grid';

  static bool get _isIncomeEnabled => getIt<FeatureFlags>().isEnabled(Feature.income);

  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.home.toPath,
    observers: [DebuggerRouteObserver()],
    redirect: (context, state) => authRedirect(
      BlocProvider.of<AuthBloc>(context).state,
      state.matchedLocation,
      getIt<FeatureFlags>(),
    ),
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
                  create: (context) => ItemListCubit(
                    getIt<ItemRepository>(),
                    getIt<CurrentShop>(),
                    grid: getIt<SharedPreferences>().getBool(_itemGridKey) ??
                        false,
                    onGridChanged: (grid) => unawaited(
                      getIt<SharedPreferences>().setBool(_itemGridKey, grid),
                    ),
                  ),
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
            path: AppRoutes.formItem.toPath,
            name: AppRoutes.formItem,
            pageBuilder: (BuildContext context, GoRouterState state) {
              GlobalContext.currentContext = context;
              final extra = state.extra! as Map<String, dynamic>;
              final existingItem = extra['existingItem'] as Item?;
              final scan = getIt<FeatureFlags>().isEnabled(Feature.barcodeScan);
              return CustomTransitionPage(
                key: state.pageKey,
                child: BlocProvider(
                  create: (_) => ItemFormCubit(
                    getIt<ItemRepository>(),
                    existing: existingItem,
                  )..load(),
                  child: ItemFormPage(
                    scanBarcode: scan ? scanBarcode : null,
                    barcode: extra['barcode'] as String?,
                    name: extra['name'] as String?,
                  ),
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
              final customerBloc = extra?['customerBloc'] as CustomerBloc? ?? context.read<CustomerBloc>();
              final incomeBloc = extra?['incomeBloc'] as IncomeBloc? ?? _maybeReadIncomeBloc(context);
              final signoutBloc = extra?['signoutBloc'] as SignoutBloc? ?? context.read<SignoutBloc>();
              GlobalContext.currentContext = context;

              return CustomTransitionPage(
                key: state.pageKey,
                child: MultiBlocProvider(
                  providers: [
                    BlocProvider.value(value: customerBloc),
                    if (incomeBloc != null) BlocProvider.value(value: incomeBloc),
                    BlocProvider.value(value: signoutBloc),
                    // Shared with the Prices & currency screen, so its
                    // changes show in the Settings row on return.
                    BlocProvider(
                      create: (_) => PriceSettingsCubit(
                        getIt<ItemRepository>(),
                        getIt<CurrentShop>(),
                      )..load(),
                    ),
                    BlocProvider(
                      create: (_) => CategoriesCubit(
                        getIt<ItemRepository>(),
                        getIt<CurrentShop>(),
                      )..load(),
                    ),
                  ],
                  child: const SettingsPage(),
                ),
                transitionsBuilder: _rightToLeftTransition,
              );
            },
          ),
          GoRoute(
            path: AppRoutes.priceSettings.toPath,
            name: AppRoutes.priceSettings,
            pageBuilder: (BuildContext context, GoRouterState state) {
              GlobalContext.currentContext = context;
              final extra = state.extra! as Map<String, dynamic>;
              final cubit = extra['priceSettingsCubit'] as PriceSettingsCubit;
              return CustomTransitionPage(
                key: state.pageKey,
                child: BlocProvider.value(
                  value: cubit,
                  child: const PriceSettingsPage(),
                ),
                transitionsBuilder: _rightToLeftTransition,
              );
            },
          ),
          GoRoute(
            path: AppRoutes.categoriesUnits.toPath,
            name: AppRoutes.categoriesUnits,
            pageBuilder: (BuildContext context, GoRouterState state) {
              GlobalContext.currentContext = context;
              final extra = state.extra! as Map<String, dynamic>;
              final cubit = extra['categoriesCubit'] as CategoriesCubit;
              return CustomTransitionPage(
                key: state.pageKey,
                child: BlocProvider.value(
                  value: cubit,
                  child: const CategoriesUnitsPage(),
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
        path: AppRoutes.chooseUsername.toPath,
        name: AppRoutes.chooseUsername,
        pageBuilder: (BuildContext context, GoRouterState state) {
          GlobalContext.currentContext = context;
          return CustomTransitionPage(
            key: state.pageKey,
            child: BlocProvider(
              create: (context) => ProfileBloc(
                getIt<UploadBloc>(),
                getIt<ProfileService>(),
              ),
              child: const ChooseUsernamePage(),
            ),
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
