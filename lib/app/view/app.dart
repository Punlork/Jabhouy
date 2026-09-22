import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_runtime_debugger/flutter_runtime_debugger.dart';
import 'package:jabhouy/app/app.dart';
import 'package:jabhouy/auth/auth.dart';
import 'package:jabhouy_l10n/jabhouy_l10n.dart';
import 'package:jabhouy_ui/jabhouy_ui.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => getIt<AuthBloc>(),
        ),
        BlocProvider(
          create: (context) => getIt<AppBloc>(),
        ),
      ],
      child: const _MyApp(),
    );
  }
}

class _MyApp extends StatelessWidget {
  const _MyApp();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppBloc, AppState>(
      builder: (context, state) {
        return MaterialApp.router(
          locale: state.locale,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: state.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          builder: (context, child) => Overlay(
            initialEntries: [
              OverlayEntry(
                builder: (context) => Debugger.builder(
                  context,
                  AppUpgrader(child: child!),
                ),
              ),
            ],
          ),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerDelegate: AppRouter.router.routerDelegate,
          routeInformationProvider: AppRouter.router.routeInformationProvider,
          routeInformationParser: AppRouter.router.routeInformationParser,
        );
      },
    );
  }
}
