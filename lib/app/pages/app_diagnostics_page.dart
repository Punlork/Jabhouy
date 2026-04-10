import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:my_app/app/app.dart';
import 'package:my_app/income/income.dart';
import 'package:my_app/l10n/arb/app_localizations.dart';

class AppDiagnosticsPage extends StatefulWidget {
  const AppDiagnosticsPage({super.key});

  @override
  State<AppDiagnosticsPage> createState() => _AppDiagnosticsPageState();
}

class _AppDiagnosticsPageState extends State<AppDiagnosticsPage> {
  late final AppLogService _appLogService;
  late final NetworkInspectorService _networkInspectorService;
  StreamSubscription<List<AppLogEntry>>? _appLogSubscription;
  StreamSubscription<List<NetworkLogEntry>>? _networkSubscription;
  List<AppLogEntry> _appLogs = const [];
  List<NetworkLogEntry> _networkLogs = const [];

  @override
  void initState() {
    super.initState();
    _appLogService = getIt<AppLogService>();
    _networkInspectorService = getIt<NetworkInspectorService>();
    _appLogs = _appLogService.entries;
    _networkLogs = _networkInspectorService.entries;
    _appLogSubscription = _appLogService.entriesStream.listen((entries) {
      if (!mounted) {
        return;
      }
      setState(() {
        _appLogs = entries;
      });
    });
    _networkSubscription =
        _networkInspectorService.entriesStream.listen((entries) {
      if (!mounted) {
        return;
      }
      setState(() {
        _networkLogs = entries;
      });
    });
  }

  @override
  void dispose() {
    _appLogSubscription?.cancel();
    _networkSubscription?.cancel();
    super.dispose();
  }

  Future<void> _copyAppLogs(AppLocalizations l10n) async {
    final buffer = StringBuffer();
    for (final entry in _appLogs.reversed) {
      buffer
        ..writeln(
          '[${_formatTimestamp(entry.timestamp)}] ${entry.level.toUpperCase()} ${entry.source}',
        )
        ..writeln(entry.message);
      if (entry.details != null && entry.details!.isNotEmpty) {
        buffer.writeln(entry.details);
      }
      buffer.writeln();
    }

    await Clipboard.setData(ClipboardData(text: buffer.toString()));
    if (!mounted) {
      return;
    }
    showSuccessSnackBar(context, l10n.diagnosticsCopied);
  }

  Future<void> _copyNetworkLogs(AppLocalizations l10n) async {
    final buffer = StringBuffer();
    for (final entry in _networkLogs.reversed) {
      buffer
        ..writeln(
          '[${_formatTimestamp(entry.timestamp)}] ${entry.method} ${entry.uri}',
        )
        ..writeln('${l10n.statusLabel}: ${entry.statusCode ?? '-'}')
        ..writeln('${l10n.durationLabel}: ${_formatDuration(entry.duration)}');
      if (entry.requestHeaders.isNotEmpty) {
        buffer
          ..writeln(l10n.requestHeadersLabel)
          ..writeln(
            const JsonEncoder.withIndent('  ').convert(entry.requestHeaders),
          );
      }
      if (entry.requestBody case final body?) {
        buffer
          ..writeln(l10n.requestBodyLabel)
          ..writeln(body);
      }
      if (entry.responseHeaders.isNotEmpty) {
        buffer
          ..writeln(l10n.responseHeadersLabel)
          ..writeln(
            const JsonEncoder.withIndent('  ').convert(entry.responseHeaders),
          );
      }
      if (entry.responseBody case final body?) {
        buffer
          ..writeln(l10n.responseBodyLabel)
          ..writeln(body);
      }
      if (entry.error case final error?) {
        buffer
          ..writeln(l10n.errorLabel)
          ..writeln(error);
      }
      buffer.writeln();
    }

    await Clipboard.setData(ClipboardData(text: buffer.toString()));
    if (!mounted) {
      return;
    }
    showSuccessSnackBar(context, l10n.diagnosticsCopied);
  }

  void _openNotificationDiagnostics(
    BuildContext context,
    IncomeBloc incomeBloc,
  ) {
    context.pushNamed(
      AppRoutes.incomeDiagnostics,
      extra: {
        'incomeBloc': incomeBloc,
      },
    );
  }

  String _formatTimestamp(DateTime value) {
    final local = value.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    final second = local.second.toString().padLeft(2, '0');
    return '$hour:$minute:$second';
  }

  String _formatDuration(Duration value) {
    if (value.inMilliseconds < 1000) {
      return '${value.inMilliseconds} ms';
    }
    return '${value.inMilliseconds / 1000} s';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.diagnostics),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          BlocBuilder<AppBloc, AppState>(
            builder: (context, state) {
              final incomeBloc = _maybeReadIncomeBloc(context);
              return _SectionCard(
                title: l10n.runtimeCapture,
                child: Column(
                  children: [
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      secondary: Icon(
                        Icons.article_outlined,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      title: Text(
                        l10n.appLogs,
                        style: AppTextTheme.body,
                      ),
                      subtitle: Text(
                        state.isAppLogCaptureEnabled
                            ? l10n.appLogsEnabled
                            : l10n.appLogsDisabled,
                        style: AppTextTheme.caption,
                      ),
                      value: state.isAppLogCaptureEnabled,
                      onChanged: (value) {
                        context
                            .read<AppBloc>()
                            .add(SwitchAppLogCapture(isEnabled: value));
                      },
                    ),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      secondary: Icon(
                        Icons.network_check_rounded,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      title: Text(
                        l10n.networkInspector,
                        style: AppTextTheme.body,
                      ),
                      subtitle: Text(
                        state.isNetworkLogCaptureEnabled
                            ? l10n.networkLogsEnabled
                            : l10n.networkLogsDisabled,
                        style: AppTextTheme.caption,
                      ),
                      value: state.isNetworkLogCaptureEnabled,
                      onChanged: (value) {
                        context
                            .read<AppBloc>()
                            .add(SwitchNetworkLogCapture(isEnabled: value));
                      },
                    ),
                    if (incomeBloc != null) ...[
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              _openNotificationDiagnostics(context, incomeBloc),
                          icon: const Icon(Icons.notifications_active_outlined),
                          label: Text(l10n.notificationDiagnostics),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: l10n.appLogs,
            trailing: Wrap(
              spacing: 8,
              children: [
                TextButton(
                  onPressed: () => _copyAppLogs(l10n),
                  child: Text(l10n.copyLogs),
                ),
                TextButton(
                  onPressed: _appLogService.clear,
                  child: Text(l10n.clearLogs),
                ),
              ],
            ),
            child: _appLogs.isEmpty
                ? Text(l10n.noAppLogs)
                : Column(
                    children: _appLogs.reversed
                        .map(
                          (entry) => Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '[${_formatTimestamp(entry.timestamp)}] ${entry.level.toUpperCase()} - ${entry.source}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelMedium
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 6),
                                SelectableText(entry.message),
                                if (entry.details case final details?) ...[
                                  const SizedBox(height: 8),
                                  SelectableText(
                                    details,
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
          const SizedBox(height: 16),
          _SectionCard(
            title: l10n.networkInspector,
            trailing: Wrap(
              spacing: 8,
              children: [
                TextButton(
                  onPressed: () => _copyNetworkLogs(l10n),
                  child: Text(l10n.copyLogs),
                ),
                TextButton(
                  onPressed: _networkInspectorService.clear,
                  child: Text(l10n.clearLogs),
                ),
              ],
            ),
            child: _networkLogs.isEmpty
                ? Text(l10n.noNetworkLogs)
                : Column(
                    children: _networkLogs.reversed
                        .map(
                          (entry) => Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Theme(
                              data: Theme.of(context).copyWith(
                                dividerColor: Colors.transparent,
                              ),
                              child: ExpansionTile(
                                tilePadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                childrenPadding: const EdgeInsets.fromLTRB(
                                  12,
                                  0,
                                  12,
                                  12,
                                ),
                                title: Text(
                                  '${entry.method} ${entry.uri.path}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextTheme.body.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  '${entry.statusCode ?? '-'} • ${_formatDuration(entry.duration)}',
                                  style: AppTextTheme.caption,
                                ),
                                children: [
                                  _StatusLine(
                                    label: l10n.capturedAtLabel,
                                    value: _formatTimestamp(entry.timestamp),
                                  ),
                                  _StatusLine(
                                    label: l10n.statusLabel,
                                    value: '${entry.statusCode ?? '-'}',
                                  ),
                                  _StatusLine(
                                    label: l10n.durationLabel,
                                    value: _formatDuration(entry.duration),
                                  ),
                                  _StatusLine(
                                    label: l10n.requestLabel,
                                    value: entry.uri.toString(),
                                  ),
                                  if (entry.requestHeaders.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    _DetailBlock(
                                      label: l10n.requestHeadersLabel,
                                      value: const JsonEncoder.withIndent('  ')
                                          .convert(entry.requestHeaders),
                                    ),
                                  ],
                                  if (entry.requestBody
                                      case final requestBody?) ...[
                                    const SizedBox(height: 8),
                                    _DetailBlock(
                                      label: l10n.requestBodyLabel,
                                      value: requestBody,
                                    ),
                                  ],
                                  if (entry.responseHeaders.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    _DetailBlock(
                                      label: l10n.responseHeadersLabel,
                                      value: const JsonEncoder.withIndent('  ')
                                          .convert(entry.responseHeaders),
                                    ),
                                  ],
                                  if (entry.responseBody
                                      case final responseBody?) ...[
                                    const SizedBox(height: 8),
                                    _DetailBlock(
                                      label: l10n.responseBodyLabel,
                                      value: responseBody,
                                    ),
                                  ],
                                  if (entry.error case final error?) ...[
                                    const SizedBox(height: 8),
                                    _DetailBlock(
                                      label: l10n.errorLabel,
                                      value: error,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        )
                        .toList(growable: false),
                  ),
          ),
        ],
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
      padding: const EdgeInsets.only(bottom: 4),
      child: RichText(
        text: TextSpan(
          style: Theme.of(context).textTheme.bodyMedium,
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}

class _DetailBlock extends StatelessWidget {
  const _DetailBlock({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context)
              .textTheme
              .labelMedium
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        SelectableText(value),
      ],
    );
  }
}

IncomeBloc? _maybeReadIncomeBloc(BuildContext context) {
  try {
    return context.read<IncomeBloc>();
  } on ProviderNotFoundException {
    return null;
  }
}
