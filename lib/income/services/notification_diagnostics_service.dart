import 'dart:async';

import 'package:async/async.dart' show AsyncMemoizer;
import 'package:jabhouy/income/income.dart';

/// Implements [IncomeDiagnostics] so `logic/` can log without
/// importing the Android bridge this reaches through.
class NotificationDiagnosticsService implements IncomeDiagnostics {
  NotificationDiagnosticsService(this._bridge);

  final NotificationTrackingBridge _bridge;
  final _entriesController =
      StreamController<List<NotificationDiagnosticEntry>>.broadcast();

  StreamSubscription<Map<String, dynamic>>? _logSubscription;
  List<NotificationDiagnosticEntry> _entries = const [];
  final _initialization = AsyncMemoizer<void>();

  List<NotificationDiagnosticEntry> get entries => _entries;
  Stream<List<NotificationDiagnosticEntry>> get entriesStream =>
      _entriesController.stream;

  /// Concurrent callers share one load, so none of them reads [entries]
  /// before the stored logs arrive.
  Future<void> initialize() => _initialization.runOnce(_initialize);

  Future<void> _initialize() async {
    final existingEntries = await _bridge.getDiagnosticsLogs();
    _entries = existingEntries
        .map(NotificationDiagnosticEntry.fromMap)
        .toList(growable: false);
    _entriesController.add(_entries);

    _logSubscription = _bridge.diagnosticLogStream.listen((event) {
      final nextEntry = NotificationDiagnosticEntry.fromMap(event);
      _entries = [..._entries, nextEntry];
      _entriesController.add(_entries);
    });
  }

  @override
  Future<void> log({
    required String source,
    required String message,
    String level = 'info',
    Map<String, dynamic>? metadata,
  }) {
    return _bridge.appendDiagnosticsLog(
      source: source,
      message: message,
      level: level,
      metadata: metadata,
    );
  }

  Future<void> clear() async {
    await _bridge.clearDiagnosticsLogs();
    _entries = const [];
    _entriesController.add(_entries);
  }

  Future<void> dispose() async {
    await _logSubscription?.cancel();
    await _entriesController.close();
  }
}
