import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:jabhouy_net/jabhouy_net.dart';
import 'package:jabhouy_sync/jabhouy_sync.dart';

/// Starts background sync at the moments that call for it.
///
/// With `Feature.backgroundSync` on, screens never ask the server for a
/// list; this is the one place that does, besides pull-to-refresh. The
/// engine's own window keeps it to at most one download per list per
/// 15 minutes however often these fire.
class SyncCoordinator {
  SyncCoordinator(this._engine, this._connectivity);

  final SyncEngine _engine;
  final ConnectivityService _connectivity;

  StreamSubscription<bool>? _connection;
  AppLifecycleListener? _lifecycle;

  bool get isRunning => _connection != null;

  /// After sign-in. Safe to call again while running.
  void start() {
    if (isRunning) return;
    _connection = _connectivity.connectivityStream.listen((isOnline) {
      if (isOnline) unawaited(_sync(afterReconnect: true));
    });
    _lifecycle = AppLifecycleListener(onResume: () => unawaited(_sync()));
    unawaited(_sync());
  }

  /// On sign-out, so a signed-out app stops talking to the server.
  void stop() {
    unawaited(_connection?.cancel());
    _connection = null;
    _lifecycle?.dispose();
    _lifecycle = null;
  }

  Future<void> _sync({bool afterReconnect = false}) async {
    if (!await _connectivity.isOnline) return;
    // Pushes that failed while the "connection" had no internet are
    // waiting out their backoff; a real reconnect is reason to try now.
    if (afterReconnect) await _engine.retryNow();
    // Drains first, then pulls whatever is stale.
    await _engine.pull();
  }
}
