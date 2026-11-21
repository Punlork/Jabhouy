import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:jabhouy/app/app.dart';
import 'package:jabhouy_core/jabhouy_core.dart';
import 'package:jabhouy_l10n/jabhouy_l10n.dart';

/// Updates come from Google Play only. On launch and whenever the app
/// returns to the foreground (at most once a day) it asks Play whether a
/// newer build exists.
///
/// Play's update priority (0-5, set when the release is published) picks the
/// mode: [_blockingPriority] and up forces a full-screen immediate update,
/// anything lower downloads in the background and offers a restart.
/// Sideloaded and debug builds are not installed by Play, so the check
/// fails quietly and the app carries on.
class AppUpgrader extends StatefulWidget {
  const AppUpgrader({required this.child, super.key});

  final Widget child;

  @override
  State<AppUpgrader> createState() => _AppUpgraderState();
}

const _blockingPriority = 4;
const _checkEvery = Duration(days: 1);

class _AppUpgraderState extends State<AppUpgrader>
    with WidgetsBindingObserver {
  DateTime? _lastCheck;
  bool _isChecking = false;
  StreamSubscription<InstallStatus>? _installStatus;

  @override
  void initState() {
    super.initState();
    if (!Platform.isAndroid) return;
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_installStatus?.cancel());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(_check());
  }

  Future<void> _check() async {
    final last = _lastCheck;
    if (!mounted ||
        _isChecking ||
        (last != null && DateTime.now().difference(last) < _checkEvery)) {
      return;
    }
    _isChecking = true;
    try {
      final info = await InAppUpdate.checkForUpdate();
      _lastCheck = DateTime.now();

      // An immediate update the user left half-done must be finished.
      final resume =
          info.updateAvailability ==
          UpdateAvailability.developerTriggeredUpdateInProgress;
      final available =
          info.updateAvailability == UpdateAvailability.updateAvailable;
      if (!resume && !available) return;

      if (info.immediateUpdateAllowed &&
          (resume || info.updatePriority >= _blockingPriority)) {
        await InAppUpdate.performImmediateUpdate();
      } else if (available && info.flexibleUpdateAllowed) {
        await _startFlexible();
      }
    } on Object catch (error, stackTrace) {
      // Not installed from Play (debug, sideload) or Play unavailable.
      logger.i('In-app update check skipped: $error', stackTrace: stackTrace);
    } finally {
      _isChecking = false;
    }
  }

  Future<void> _startFlexible() async {
    await _installStatus?.cancel();
    _installStatus = InAppUpdate.installUpdateListener.listen((status) {
      if (status == InstallStatus.downloaded) _offerRestart();
    });
    // Play shows its own consent dialog, then downloads in the background.
    await InAppUpdate.startFlexibleUpdate();
  }

  void _offerRestart() {
    final context = AppRouter
        .router
        .routerDelegate
        .navigatorKey
        .currentState
        ?.overlay
        ?.context;
    if (context == null || !context.mounted) return;
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(
        content: Text(l10n.updateAvailableTitle),
        duration: const Duration(days: 1),
        action: SnackBarAction(
          label: l10n.updateNow,
          onPressed: () => unawaited(InAppUpdate.completeFlexibleUpdate()),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
