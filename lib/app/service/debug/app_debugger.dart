import 'package:flutter/foundation.dart';
import 'package:flutter_runtime_debugger/flutter_runtime_debugger.dart';
import 'package:jabhouy/app/constant/app_flavor.dart';
import 'package:jabhouy/app/injection/dependency_injection.dart';
import 'package:jabhouy/app/service/debug/debug_storage_readers.dart';
import 'package:jabhouy_core/jabhouy_core.dart';
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
/// allocated and no overlay ships. The development flavor also runs in
/// release (the CI dev APK is one), where the plain [DebuggerConfig] would
/// disable itself, so it takes a gate that starts unlocked.
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
    // The flavor still decides *whether* to initialize at all — that check
    // lives in [initialize]. Only the development flavor gets here.
    final version = await _appVersion();
    if (!kReleaseMode) return DebuggerConfig(appVersion: version);
    // shortcut: the gate starts unlocked, so every dev release shows the
    // bubble; the dev backend holds no real data. Use a tap gate (the
    // version label) before sharing a dev build outside the team.
    return DebuggerConfig.gated(
      gate: SecretGestureGate(initiallyUnlocked: true),
      captureNetworkBodies: true,
      captureStorage: true,
      appVersion: version,
    );
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
