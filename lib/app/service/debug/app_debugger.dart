import 'package:flutter_runtime_debugger/flutter_runtime_debugger.dart';
import 'package:my_app/app/constant/app_flavor.dart';
import 'package:my_app/app/injection/dependency_injection.dart';
import 'package:my_app/app/service/database/app_database.dart';
import 'package:my_app/app/service/debug/debug_storage_readers.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Wires `flutter_runtime_debugger` into the app.
///
/// Two phases, because the overlay must intercept crashes as early as
/// possible but the Storage tab needs the DI container to be ready:
///
/// 1. [initialize] — before dependency setup. Installs the crash handler,
///    FPS monitor and State tab.
/// 2. [attachStorage] — after `setupDependencies()`. Registers the Storage
///    tab readers.
///
/// Production builds intentionally initialize nothing: no buffers are
/// allocated and no overlay ships. To hand a gated overlay to external
/// testers, prefer a `--profile` build (where the plain [DebuggerConfig]
/// works fully) over switching to [DebuggerConfig.gated] here.
class AppDebugger {
  const AppDebugger._();

  static AppFlavor _flavor = AppFlavor.production;

  static bool get isEnabled => DebuggerController.instance.enabled;

  static Future<void> initialize(AppFlavor flavor) async {
    _flavor = flavor;
    if (flavor.isProduction) return;

    final config = await _configFor(flavor);
    Debugger.init(config);

    if (!DebuggerController.instance.enabled) return;

    // Registers the State tab; entries are fed by AppBlocObserver.
    StateRecorder.init();
  }

  static void attachStorage() {
    if (_flavor.isProduction) return;
    if (!DebuggerController.instance.enabled) return;
    if (!DebuggerController.instance.captureStorage) return;

    StorageRecorder.attach([
      DriftStorageReader(getIt<AppDatabase>()),
      const SharedPreferencesStorageReader(),
    ]);
  }

  static Future<DebuggerConfig> _configFor(AppFlavor flavor) async {
    // Every non-production flavor gets the same thing: an ungated config,
    // which disables itself in release builds. The flavor still decides
    // *whether* to initialize at all — that check lives in [initialize].
    return DebuggerConfig(appVersion: await _appVersion());
  }

  static Future<String?> _appVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      return '${info.version}+${info.buildNumber}';
    } catch (_) {
      return null;
    }
  }
}
