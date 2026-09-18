import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_runtime_debugger/flutter_runtime_debugger.dart';
import 'package:jabhouy/app/app.dart';
import 'package:jabhouy/app/service/firebase_runtime_options.dart';

class AppBlocObserver extends BlocObserver {
  const AppBlocObserver();

  static final logger = LoggerFactory.createLogger(
    methodCount: 0,
    printTime: false,
    lineLength: 200,
  );

  @override
  void onChange(BlocBase<dynamic> bloc, Change<dynamic> change) {
    super.onChange(bloc, change);
    logger.d(
      'Bloc: ${bloc.runtimeType}\n'
      'Current State: ${change.currentState.runtimeType}\n'
      'Next State: ${change.nextState.runtimeType}',
    );
  }

  /// Feeds the debug overlay's State tab. Only fires for event-driven blocs,
  /// which is what gives each entry its triggering event.
  @override
  void onTransition(
    Bloc<dynamic, dynamic> bloc,
    Transition<dynamic, dynamic> transition,
  ) {
    super.onTransition(bloc, transition);
    StateRecorder.record(
      manager: bloc.runtimeType.toString(),
      trigger: transition.event.runtimeType.toString(),
      from: transition.currentState.runtimeType.toString(),
      to: transition.nextState.runtimeType.toString(),
    );
  }

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    logger.e(
      'Bloc: ${bloc.runtimeType}\n'
      'Error: $error\n'
      'Stack Trace: $stackTrace',
      error: error,
      stackTrace: stackTrace,
    );
    Debugger.error(
      '$error',
      tag: bloc.runtimeType.toString(),
      stackTrace: stackTrace,
    );

    super.onError(bloc, error, stackTrace);
  }
}

Future<void> bootstrap(
  FutureOr<Widget> Function() builder, {
  required AppFlavor flavor,
  Future<void> Function()? initialize,
}) async {
  final appLogService = AppLogService.instance;

  await runZonedGuarded(
    () async {
      final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

      if (initialize != null) await initialize();

      FlutterError.onError = (details) {
        LoggerFactory.createLogger(
          printTime: false,
          lineLength: 80,
          errorMethodCount: 0,
          methodCount: 0,
        ).e(
          'Flutter Error:\n'
          'Exception: ${details.exceptionAsString()}\n'
          'Library: ${details.library}\n'
          'Context: ${details.context}\n'
          'Stack Trace: ${details.stack}',
          error: details.exception,
          stackTrace: details.stack,
        );
      };

      PlatformDispatcher.instance.onError = (error, stackTrace) {
        logger.e(
          'Platform Error: $error',
          error: error,
          stackTrace: stackTrace,
        );
        return true;
      };

      // Must come after the handlers above: the debugger's crash handler
      // wraps whatever is currently installed and delegates to it, so
      // initializing earlier would let those assignments replace it.
      await AppDebugger.initialize(flavor);

      Bloc.observer = const AppBlocObserver();

      FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

      FcmService.setupBackgroundHandler();

      await FirebaseRuntimeOptions.initialize();
      if (Firebase.apps.isNotEmpty) {
        await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true);
      }
      await FirebaseRuntimeOptions.persistNativeSyncConfig();
      await setupDependencies();

      // Storage tab needs the DI container, so it attaches after setup.
      AppDebugger.attachStorage();

      await getIt<FcmService>().initialize();
      runApp(await builder());
    },
    (error, stackTrace) {
      logger.e(
        'Uncaught zone error: $error',
        error: error,
        stackTrace: stackTrace,
      );
      Debugger.error('$error', tag: 'zone', stackTrace: stackTrace);
    },
    zoneSpecification: ZoneSpecification(
      print: (self, parent, zone, line) {
        appLogService.capturePrint(line);
        parent.print(zone, line);
        Debugger.log(line, tag: 'print', level: LogLevel.verbose);
      },
    ),
  );
}
