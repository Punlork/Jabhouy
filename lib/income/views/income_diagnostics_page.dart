import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_app/app/app.dart';
import 'package:my_app/income/income.dart';

class IncomeDiagnosticsPage extends StatefulWidget {
  const IncomeDiagnosticsPage({super.key});

  @override
  State<IncomeDiagnosticsPage> createState() => _IncomeDiagnosticsPageState();
}

class _IncomeDiagnosticsPageState extends State<IncomeDiagnosticsPage> {
  late final NotificationDiagnosticsService _diagnosticsService;
  late final NotificationTrackingBridge _trackingBridge;
  StreamSubscription<List<NotificationDiagnosticEntry>>?
      _diagnosticsSubscription;
  List<NotificationDiagnosticEntry> _entries = const [];

  @override
  void initState() {
    super.initState();
    _diagnosticsService = getIt<NotificationDiagnosticsService>();
    _trackingBridge = getIt<NotificationTrackingBridge>();
    _entries = _diagnosticsService.entries;
    _diagnosticsSubscription =
        _diagnosticsService.entriesStream.listen((entries) {
      if (!mounted) return;
      setState(() {
        _entries = entries;
      });
    });
    unawaited(_diagnosticsService.initialize());
  }

  @override
  void dispose() {
    _diagnosticsSubscription?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    context.read<IncomeBloc>().add(const RefreshIncomeTrackingStatus());
    await _diagnosticsService.initialize();
    setState(() {
      _entries = _diagnosticsService.entries;
    });
  }

  Future<void> _clearLogs() async {
    await _diagnosticsService.clear();
  }

  Future<void> _copyLogs() async {
    final buffer = StringBuffer();
    for (final entry in _entries.reversed) {
      buffer
        ..writeln(
          '[${entry.timeLabel}] ${entry.level.toUpperCase()} ${entry.source}',
        )
        ..writeln(entry.message);
      if (entry.metadata.isNotEmpty) {
        buffer.writeln(entry.metadataLabel);
      }
      buffer.writeln();
    }

    await Clipboard.setData(ClipboardData(text: buffer.toString()));
    if (!mounted) return;
    showSuccessSnackBar(context, 'Diagnostics copied');
  }

  Future<void> _copyEntryMetadata(NotificationDiagnosticEntry entry) async {
    final text = entry.metadata.isEmpty ? entry.message : entry.metadataLabel;
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    showSuccessSnackBar(context, 'Payload copied');
  }

  Future<void> _sendNativeTestPush(
    BankNotificationModel? latestItem,
  ) async {
    final now = DateTime.now();
    final sample = latestItem ??
        BankNotificationModel(
          fingerprint: 'native-test-${now.millisecondsSinceEpoch}',
          packageName: 'com.paygo24.ibank',
          bankApp: BankApp.aba,
          title: 'Income received',
          message: 'Manual native test push',
          amount: 1,
          currency: 'USD',
          isIncome: true,
          receivedAt: now,
          source: 'manual_native_test',
        );

    final payload = <String, dynamic>{
      'fingerprint': sample.fingerprint,
      'packageName': sample.packageName,
      'bankKey': sample.bankApp.key,
      'title': sample.title ?? '',
      'message': sample.message,
      'amount': sample.amount,
      'currency': sample.currency,
      'isIncome': sample.isIncome,
      'receivedAt': sample.receivedAt.millisecondsSinceEpoch,
      'source': sample.source,
    };

    try {
      final sent = await _trackingBridge.sendNativeTestPush(payload);
      if (!mounted) return;
      if (sent) {
        showSuccessSnackBar(context, 'Native push test sent');
      } else {
        showErrorSnackBar(context, 'Native push test was not sent');
      }
    } on PlatformException catch (error) {
      if (!mounted) return;
      showErrorSnackBar(
        context,
        error.message ?? 'Native push test failed',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<IncomeBloc>().state.asLoaded;
    final trackingStatus = state?.trackingStatus;
    final deviceRole = context.select((AppBloc bloc) => bloc.state.deviceRole);
    final recentItems = (state?.items ?? const <BankNotificationModel>[])
        .take(5)
        .toList(growable: false);
    NotificationDiagnosticEntry? latestFcmPayloadEntry;
    for (final entry in _entries.reversed) {
      if (entry.source == 'flutter.fcm' &&
          entry.message ==
              'Prepared FCM token payload for backend registration.') {
        latestFcmPayloadEntry = entry;
        break;
      }
    }
    final fcmPayloadEntry = latestFcmPayloadEntry;
    final fcmPayloadCardTrailing = fcmPayloadEntry == null
        ? null
        : TextButton(
            onPressed: () => _copyEntryMetadata(fcmPayloadEntry),
            child: const Text('Copy'),
          );
    final fcmPayloadCardChild = fcmPayloadEntry == null
        ? const Text('No FCM token payload captured yet.')
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _StatusLine(
                label: 'Captured at',
                value: fcmPayloadEntry.timeLabel,
              ),
              const SizedBox(height: 8),
              SelectableText(
                fcmPayloadEntry.metadataLabel,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Diagnostics'),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            _SectionCard(
              title: 'Tracking status',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _StatusLine(
                    label: 'Device role',
                    value: deviceRole.storageValue,
                  ),
                  _StatusLine(
                    label: 'Notification access',
                    value: '${trackingStatus?.isAccessEnabled ?? false}',
                  ),
                  _StatusLine(
                    label: 'Supported platform',
                    value: '${trackingStatus?.isSupported ?? false}',
                  ),
                  _StatusLine(
                    label: 'Can capture locally',
                    value: '${trackingStatus?.canCaptureLocally ?? false}',
                  ),
                  _StatusLine(
                    label: 'Blocked by another main device',
                    value:
                        '${trackingStatus?.isBlockedByAnotherMainDevice ?? false}',
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilledButton.icon(
                        onPressed: () => context
                            .read<IncomeBloc>()
                            .add(const RefreshIncomeTrackingStatus()),
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Refresh status'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => _sendNativeTestPush(
                          recentItems.isEmpty ? null : recentItems.first,
                        ),
                        icon: const Icon(Icons.send_rounded),
                        label: const Text('Send native push test'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => context
                            .read<IncomeBloc>()
                            .add(const OpenNotificationAccessSettings()),
                        icon: const Icon(Icons.settings_rounded),
                        label: const Text('Open access settings'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Recently stored notifications',
              child: recentItems.isEmpty
                  ? const Text('No notifications stored yet.')
                  : Column(
                      children: recentItems
                          .map(
                            (item) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                item.title?.isNotEmpty ?? false
                                    ? item.title!
                                    : item.message,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                '${item.packageName}\n${item.receivedDateLabel} ${item.receivedTimeLabel}',
                              ),
                              trailing: Text(item.bankApp.key),
                            ),
                          )
                          .toList(growable: false),
                    ),
            ),
            const SizedBox(height: 16),
            _SectionCard(
              title: 'FCM token payload',
              trailing: fcmPayloadCardTrailing,
              child: fcmPayloadCardChild,
            ),
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Event log',
              trailing: Wrap(
                spacing: 8,
                children: [
                  TextButton(
                    onPressed: _copyLogs,
                    child: const Text('Copy'),
                  ),
                  TextButton(
                    onPressed: _clearLogs,
                    child: const Text('Clear'),
                  ),
                ],
              ),
              child: _entries.isEmpty
                  ? const Text('No diagnostic events yet.')
                  : Column(
                      children: _entries.reversed
                          .map(
                            (entry) => Container(
                              width: double.infinity,
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '[${entry.timeLabel}] ${entry.level.toUpperCase()} - ${entry.source}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                  const SizedBox(height: 6),
                                  SelectableText(entry.message),
                                  if (entry.metadata.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    SelectableText(
                                      entry.metadataLabel,
                                      style:
                                          Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          )
                          .toList(growable: false),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
    this.trailing,
  });

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppTextTheme.title,
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _StatusLine extends StatelessWidget {
  const _StatusLine({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 180,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
