import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:my_app/app/app.dart';
import 'package:my_app/l10n/arb/app_localizations.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class AppUpgrader extends StatefulWidget {
  const AppUpgrader({
    required this.child,
    super.key,
    this.showIgnore = true,
    this.showLater = true,
  });
  final Widget child;
  final bool showIgnore;
  final bool showLater;

  @override
  State<AppUpgrader> createState() => _AppUpgraderState();
}

class _AppUpgraderState extends State<AppUpgrader> {
  static final Uri _latestReleaseUri = Uri.parse(
    'https://api.github.com/repos/Punlork/Jabhouy/releases/latest',
  );

  bool _isChecking = false;
  bool _hasPrompted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForUpdates();
    });
  }

  Future<void> _checkForUpdates() async {
    if (!mounted || _isChecking || _hasPrompted) return;

    _isChecking = true;
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final response = await http.get(
        _latestReleaseUri,
        headers: const {
          'Accept': 'application/vnd.github+json',
        },
      );

      if (response.statusCode != 200) return;

      final payload = jsonDecode(response.body);
      if (payload is! Map<String, dynamic>) return;

      final currentVersion = packageInfo.version;
      final latestVersion = _normalizeVersion(payload['tag_name']?.toString());

      if (latestVersion == null ||
          !_isRemoteVersionNewer(
            currentVersion: currentVersion,
            latestVersion: latestVersion,
          )) {
        return;
      }

      final releaseUrl = _extractReleaseUrl(payload);
      if (releaseUrl == null || !mounted) return;

      _hasPrompted = true;
      await _showUpdateSheet(
        currentVersion: currentVersion,
        latestVersion: latestVersion,
        releaseUrl: releaseUrl,
      );
    } catch (_) {
      // Ignore update-check failures and keep the app usable.
      // rethrow;
    } finally {
      _isChecking = false;
    }
  }

  Future<void> _showUpdateSheet({
    required String currentVersion,
    required String latestVersion,
    required Uri releaseUrl,
  }) async {
    final overlayContext = AppRoutes
        .router.routerDelegate.navigatorKey.currentState?.overlay?.context;
    if (overlayContext == null) return;

    final l10n = AppLocalizations.of(overlayContext);

    await showModalBottomSheet<void>(
      context: overlayContext,
      useRootNavigator: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.updateAvailableTitle,
                style: AppTextTheme.title,
              ),
              const SizedBox(height: 12),
              Text(
                l10n.updateAvailableMessage(currentVersion, latestVersion),
                style: AppTextTheme.body,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  if (widget.showLater)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(sheetContext).pop(),
                        child: Text(l10n.updateLater),
                      ),
                    ),
                  if (widget.showLater) const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final opened = await launchUrl(
                          releaseUrl,
                          mode: LaunchMode.externalApplication,
                        );
                        if (!sheetContext.mounted) return;
                        if (opened) {
                          Navigator.of(sheetContext).pop();
                        }
                      },
                      child: Text(l10n.updateNow),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Uri? _extractReleaseUrl(Map<String, dynamic> payload) {
    final assets = payload['assets'];
    if (assets is List) {
      for (final asset in assets) {
        if (asset is! Map<String, dynamic>) continue;
        final name = asset['name']?.toString().toLowerCase();
        final downloadUrl = asset['browser_download_url']?.toString();
        if (name != null && name.endsWith('.apk') && downloadUrl != null) {
          return Uri.tryParse(downloadUrl);
        }
      }
    }

    final htmlUrl = payload['html_url']?.toString();
    return htmlUrl == null ? null : Uri.tryParse(htmlUrl);
  }

  String? _normalizeVersion(String? rawVersion) {
    if (rawVersion == null || rawVersion.isEmpty) return null;
    return rawVersion.startsWith('v') ? rawVersion.substring(1) : rawVersion;
  }

  bool _isRemoteVersionNewer({
    required String currentVersion,
    required String latestVersion,
  }) {
    final currentParts = _parseVersion(currentVersion);
    final latestParts = _parseVersion(latestVersion);
    final maxLength = currentParts.length > latestParts.length
        ? currentParts.length
        : latestParts.length;

    for (var index = 0; index < maxLength; index++) {
      final currentPart = index < currentParts.length ? currentParts[index] : 0;
      final latestPart = index < latestParts.length ? latestParts[index] : 0;
      if (latestPart > currentPart) return true;
      if (latestPart < currentPart) return false;
    }

    return false;
  }

  List<int> _parseVersion(String version) {
    return version
        .split('+')
        .first
        .split('.')
        .map((part) => int.tryParse(part) ?? 0)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
