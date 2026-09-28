import 'dart:async';

import 'package:flutter/material.dart';
import 'package:jabhouy_core/jabhouy_core.dart';
import 'package:jabhouy_l10n/jabhouy_l10n.dart';
import 'package:jabhouy_net/jabhouy_net.dart';
import 'package:jabhouy_sync/jabhouy_sync.dart';
import 'package:jabhouy_ui/jabhouy_ui.dart';

/// A pill above home's bottom bar saying what sync is doing.
///
/// It replaces the per-list banners, which were English literals set by
/// each bloc from a connectivity guess. This reads the engine. It takes no
/// taps except when changes failed, where a tap lists them and why.
class SyncIndicator extends StatefulWidget {
  const SyncIndicator({
    required this.engine,
    required this.connectivity,
    super.key,
  });

  final SyncEngine engine;
  final ConnectivityService connectivity;

  /// A push shorter than this never shows "Syncing…", so a quick save
  /// does not flash the pill. Chosen, not measured.
  static const syncingDelay = Duration(seconds: 1);

  /// How long "Synced" stays after a visible sync ends. Chosen.
  static const syncedFor = Duration(milliseconds: 1500);

  @override
  State<SyncIndicator> createState() => _SyncIndicatorState();
}

enum _Pill { hidden, syncing, synced, waiting, failed }

class _SyncIndicatorState extends State<SyncIndicator> {
  StreamSubscription<SyncActivity>? _activitySub;
  StreamSubscription<bool>? _connectionSub;
  var _activity = const SyncActivity();
  var _online = true;
  var _showSyncing = false;
  var _showSynced = false;
  Timer? _syncingTimer;
  Timer? _syncedTimer;

  @override
  void initState() {
    super.initState();
    unawaited(
      widget.connectivity.isOnline.then((online) {
        if (mounted) setState(() => _online = online);
      }),
    );
    _connectionSub = widget.connectivity.connectivityStream.listen((online) {
      setState(() => _online = online);
    });
    _activitySub = widget.engine.activity.listen(_onActivity);
  }

  void _onActivity(SyncActivity next) {
    final started = next.pushing && !_activity.pushing;
    final ended = !next.pushing && _activity.pushing;
    setState(() => _activity = next);

    if (started) {
      _syncingTimer?.cancel();
      _syncingTimer = Timer(SyncIndicator.syncingDelay, () {
        if (mounted && _activity.pushing) setState(() => _showSyncing = true);
      });
    }
    if (ended) {
      _syncingTimer?.cancel();
      if (_showSyncing) {
        setState(() {
          _showSyncing = false;
          _showSynced = true;
        });
        _syncedTimer?.cancel();
        _syncedTimer = Timer(SyncIndicator.syncedFor, () {
          if (mounted) setState(() => _showSynced = false);
        });
      }
    }
  }

  @override
  void dispose() {
    unawaited(_activitySub?.cancel());
    unawaited(_connectionSub?.cancel());
    _syncingTimer?.cancel();
    _syncedTimer?.cancel();
    super.dispose();
  }

  /// Failures first: they need the seller. Then what is stuck offline,
  /// then a running sync, then its brief all-clear.
  _Pill get _pill {
    if (_activity.failing > 0) return _Pill.failed;
    if (!_online && _activity.waiting > 0) return _Pill.waiting;
    if (_showSyncing) return _Pill.syncing;
    if (_showSynced) return _Pill.synced;
    return _Pill.hidden;
  }

  @override
  Widget build(BuildContext context) {
    final pill = _pill;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: pill == _Pill.hidden
          ? const SizedBox.shrink(key: ValueKey('hidden'))
          : Padding(
              key: ValueKey(pill),
              padding: const EdgeInsets.only(bottom: 8),
              child: _PillView(
                pill: pill,
                activity: _activity,
                onTap: pill == _Pill.failed ? () => _showFailed(context) : null,
              ),
            ),
    );
  }

  Future<void> _showFailed(BuildContext context) async {
    final jobs = await widget.engine.failedJobs();
    if (!context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => _FailedJobsSheet(jobs: jobs),
    );
  }
}

class _PillView extends StatelessWidget {
  const _PillView({
    required this.pill,
    required this.activity,
    this.onTap,
  });

  final _Pill pill;
  final SyncActivity activity;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final failed = pill == _Pill.failed;

    final (IconData icon, String label) = switch (pill) {
      _Pill.failed => (
          Icons.error_outline_rounded,
          l10n.changesFailed(activity.failing),
        ),
      _Pill.waiting => (
          Icons.cloud_off_rounded,
          l10n.changesWaiting(activity.waiting),
        ),
      _Pill.syncing => (Icons.sync_rounded, l10n.syncing),
      _Pill.synced => (Icons.cloud_done_rounded, l10n.synced),
      _Pill.hidden => (Icons.circle, ''),
    };
    final foreground =
        failed ? colorScheme.onErrorContainer : colorScheme.onSurface;

    return Material(
      color: failed
          ? colorScheme.errorContainer
          : colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: foreground),
              const SizedBox(width: 8),
              Text(label, style: AppTextTheme.caption.copyWith(color: foreground)),
            ],
          ),
        ),
      ),
    );
  }
}

class _FailedJobsSheet extends StatelessWidget {
  const _FailedJobsSheet({required this.jobs});

  final List<OutboxEntry> jobs;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    String entityLabel(SyncEntityType type) => switch (type) {
          SyncEntityType.shopItem => l10n.shop,
          SyncEntityType.category => l10n.category,
          SyncEntityType.customer => l10n.customers,
          SyncEntityType.loaner => l10n.loaner,
          SyncEntityType.bankNotification => l10n.income,
        };

    return SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Text(l10n.failedChangesTitle, style: AppTextTheme.title),
          const SizedBox(height: 8),
          for (final job in jobs)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                Icons.error_outline_rounded,
                color: Theme.of(context).colorScheme.error,
              ),
              title: Text('${entityLabel(job.entityType)} #${job.localId}'),
              // The server's own words: the most precise thing to hand
              // to whoever fixes it.
              subtitle: Text(job.lastError ?? ''),
            ),
        ],
      ),
    );
  }
}
