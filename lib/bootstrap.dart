import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:my_app/app/app.dart';

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
      'Current State: ${change.currentState}\n'
      'Next State: ${change.nextState}',
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

    super.onError(bloc, error, stackTrace);
  }
}

Future<void> bootstrap(FutureOr<Widget> Function() builder) async {
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

  Bloc.observer = const AppBlocObserver();
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load();
  await setupDependencies();

  runApp(await builder());
}
