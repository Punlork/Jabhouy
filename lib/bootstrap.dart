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
  );

  @override
  void onChange(BlocBase<dynamic> bloc, Change<dynamic> change) {
    super.onChange(bloc, change);
    logger.d(
      '''
      onChange(${bloc.runtimeType})
      {
        'currentState': ${change.currentState},
        'nextState': ${change.nextState},
      }
      ''',
    );
  }

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    logger.e(
      'onError(${bloc.runtimeType}, $error)',
      error: error,
      stackTrace: stackTrace,
    );

    super.onError(bloc, error, stackTrace);
  }
}

Future<void> bootstrap(FutureOr<Widget> Function() builder) async {
  FlutterError.onError = (details) {
    logger.e(
      'FlutterError: ${details.exceptionAsString()}',
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
