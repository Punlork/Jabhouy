import 'package:jabhouy/income/data/income_diagnostics.dart';
import 'package:jabhouy/income/data/income_repository.dart';
import 'package:jabhouy_core/jabhouy_core.dart';

/// Pulls the server's notification list, stores what is new, and repairs
/// what was stored before the parser understood it.
///
/// One of the two use cases income earns, on the doc's second condition:
/// complexity. Three steps that must happen in order, a throttle that has
/// to survive between calls, and a diagnostic trail at each branch — none
/// of which is a database read or an HTTP call, so none of it belongs in
/// `data/`.
///
/// The throttle is the reason this holds state. `IncomeBloc` calls it on
/// open, on refresh and on reconnect, and the three can land within a
/// second of each other.
class PullRemoteNotificationsUseCase {
  PullRemoteNotificationsUseCase(
    this._repository,
    this._diagnostics, {
    this.clock = DateTime.now,
    this.minimumInterval = const Duration(seconds: 20),
  });

  final IncomeRepository _repository;
  final IncomeDiagnostics _diagnostics;
  /// Injectable so the throttle below is testable without waiting.
  final DateTime Function() clock;
  final Duration minimumInterval;

  static const _source = 'flutter.income';

  DateTime? _lastPullAt;

  /// Returns how many rows changed: stored plus repaired.
  Future<int> call({bool force = false}) async {
    final now = clock();
    final last = _lastPullAt;
    if (!force && last != null && now.difference(last) < minimumInterval) {
      return 0;
    }
    _lastPullAt = now;

    final result = await _repository.fetchRemote();

    if (result case Err(:final error)) {
      await _diagnostics.log(
        source: _source,
        message: 'Failed to pull remote notifications list from backend.',
        level: 'warning',
        metadata: {'message': error.message, 'statusCode': error.statusCode},
      );
      return 0;
    }

    final received = result.valueOrNull ?? const [];
    var stored = 0;
    for (final model in received) {
      if (await _repository.store(model)) stored++;
    }

    final repaired = await _repository.backfillMetadata();

    await _diagnostics.log(
      source: _source,
      message: 'Pulled remote notifications from backend.',
      metadata: {
        'receivedCount': received.length,
        'storedCount': stored,
        'repairedCount': repaired,
      },
    );

    return stored + repaired;
  }
}
