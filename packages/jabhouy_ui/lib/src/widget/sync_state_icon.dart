import 'package:flutter/material.dart';
import 'package:jabhouy_l10n/jabhouy_l10n.dart';

/// A small mark on a list row that is not on the server yet.
///
/// Synced rows show nothing, so the mark only ever means "look here".
/// Callers pass booleans rather than a `SyncStatus` so this package keeps
/// no dependency on `jabhouy_core`.
class SyncStateIcon extends StatelessWidget {
  const SyncStateIcon({
    required this.isPending,
    required this.isFailed,
    super.key,
  });

  final bool isPending;
  final bool isFailed;

  @override
  Widget build(BuildContext context) {
    if (!isPending && !isFailed) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    return Tooltip(
      message: isFailed ? l10n.syncFailed : l10n.waitingToSync,
      child: Icon(
        isFailed ? Icons.error_outline_rounded : Icons.cloud_upload_outlined,
        size: 18,
        color: isFailed ? colorScheme.error : colorScheme.onSurfaceVariant,
      ),
    );
  }
}
