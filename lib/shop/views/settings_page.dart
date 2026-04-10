import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:my_app/app/app.dart';
import 'package:my_app/auth/auth.dart';
import 'package:my_app/customer/customer.dart';
import 'package:my_app/income/income.dart';
import 'package:my_app/l10n/arb/app_localizations.dart';
import 'package:my_app/shop/shop.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  int _diagnosticsTapCount = 0;
  late final Future<String> _appVersionFuture;

  @override
  void initState() {
    super.initState();
    _appVersionFuture = _loadAppVersion();
  }

  void _handleHiddenDiagnosticsTap() {
    _diagnosticsTapCount += 1;
    if (_diagnosticsTapCount < 7) {
      return;
    }

    _diagnosticsTapCount = 0;
    _openDiagnostics();
  }

  void _openDiagnostics() {
    context.pushNamed(
      AppRoutes.appDiagnostics,
      extra: {
        'incomeBloc': context.read<IncomeBloc>(),
      },
    );
  }

  Future<void> _toggleDeviceRole({
    required bool isMainDevice,
    required AppLocalizations l10n,
  }) async {
    final syncService = getIt<FirebaseIncomeSyncService>();
    if (isMainDevice) {
      await syncService.releaseMainDeviceRole();
      if (!mounted) {
        return;
      }
      showSuccessSnackBar(context, l10n.subDeviceRole);
    } else {
      final claimed = await syncService.requestMainDeviceRole();
      if (!mounted) {
        return;
      }
      if (!claimed) {
        showErrorSnackBar(context, l10n.anotherMainDeviceActive);
      }
    }

    if (!mounted) {
      return;
    }

    context.read<AppBloc>().add(const RefreshDeviceRole());
  }

  Future<void> _confirmSignOut(AppLocalizations l10n) async {
    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          l10n.signOut,
          style: AppTextTheme.title,
        ),
        content: Text(
          l10n.confirmSignOut,
          style: AppTextTheme.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              l10n.cancel,
              style: AppTextTheme.caption,
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              l10n.signOut,
              style: AppTextTheme.caption,
            ),
          ),
        ],
      ),
    );

    if ((shouldSignOut ?? false) && mounted) {
      context.read<SignoutBloc>().add(const SignoutSubmitted());
    }
  }

  Future<String> _loadAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return '${packageInfo.version}+${packageInfo.buildNumber}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: _handleHiddenDiagnosticsTap,
          behavior: HitTestBehavior.opaque,
          child: Text(l10n.settings),
        ),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SettingsCard(
                child: Column(
                  children: [
                    _SettingsRow(
                      icon: Icons.person_outline_rounded,
                      title: l10n.profile,
                      onTap: () => context.pushNamed(AppRoutes.profile),
                    ),
                    _SectionDivider(color: colorScheme.outlineVariant),
                    _SettingsRow(
                      icon: Icons.category_outlined,
                      title: l10n.category,
                      onTap: () => context.pushNamed(
                        AppRoutes.category,
                        extra: {
                          'shop': context.read<ShopBloc>(),
                          'category': context.read<CategoryBloc>(),
                        },
                      ),
                    ),
                    _SectionDivider(color: colorScheme.outlineVariant),
                    _SettingsRow(
                      icon: Icons.people_outline_rounded,
                      title: l10n.customers,
                      onTap: () => context.pushNamed(
                        AppRoutes.customer,
                        extra: {
                          'customerBloc': context.read<CustomerBloc>(),
                        },
                      ),
                    ),
                    _SectionDivider(color: colorScheme.outlineVariant),
                    _SettingsRow(
                      icon: Icons.bug_report_outlined,
                      title: l10n.diagnostics,
                      onTap: _openDiagnostics,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              BlocBuilder<AppBloc, AppState>(
                builder: (context, state) {
                  final isMainDevice = state.deviceRole.isMain;
                  return _SettingsCard(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                isMainDevice
                                    ? Icons.phone_android_rounded
                                    : Icons.devices_rounded,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l10n.deviceRole,
                                      style: AppTextTheme.body,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      isMainDevice
                                          ? l10n.deviceRoleMainDescription
                                          : l10n.deviceRoleSubDescription,
                                      style: AppTextTheme.caption.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            l10n.singleMainDeviceHint,
                            style: AppTextTheme.caption.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: () => _toggleDeviceRole(
                              isMainDevice: isMainDevice,
                              l10n: l10n,
                            ),
                            icon: Icon(
                              isMainDevice
                                  ? Icons.sync_alt_rounded
                                  : Icons.security_update_good_rounded,
                            ),
                            label: Text(
                              isMainDevice
                                  ? l10n.releaseMainDevice
                                  : l10n.setAsMainDevice,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              _SettingsCard(
                child: Column(
                  children: [
                    BlocBuilder<AppBloc, AppState>(
                      builder: (context, state) {
                        return SwitchListTile.adaptive(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                          ),
                          secondary: Icon(
                            state.isDarkMode
                                ? Icons.dark_mode_rounded
                                : Icons.light_mode_rounded,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          title: Text(
                            l10n.darkMode,
                            style: AppTextTheme.body,
                          ),
                          subtitle: Text(
                            state.isDarkMode
                                ? l10n.darkModeOn
                                : l10n.darkModeOff,
                            style: AppTextTheme.caption.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          value: state.isDarkMode,
                          onChanged: (value) {
                            context
                                .read<AppBloc>()
                                .add(SwitchThemeMode(isDarkMode: value));
                          },
                        );
                      },
                    ),
                    _SectionDivider(color: colorScheme.outlineVariant),
                    BlocBuilder<AppBloc, AppState>(
                      builder: (context, state) {
                        final currentLocale = state.locale.languageCode;
                        return _SettingsRow(
                          icon: Icons.language_rounded,
                          title: l10n.switchLanguage,
                          subtitle: currentLocale == 'en'
                              ? l10n.languageEnglish
                              : l10n.languageKhmer,
                          onTap: () {
                            context
                                .read<AppBloc>()
                                .add(SwitchLanguage(currentLocale));
                          },
                        );
                      },
                    ),
                    _SectionDivider(color: colorScheme.outlineVariant),
                    FutureBuilder<String>(
                      future: _appVersionFuture,
                      builder: (context, snapshot) {
                        final version = snapshot.data ?? '--';
                        return _SettingsInfoRow(
                          icon: Icons.info_outline_rounded,
                          title: l10n.appVersion(version),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => _confirmSignOut(l10n),
                style: FilledButton.styleFrom(
                  backgroundColor: colorScheme.errorContainer,
                  foregroundColor: colorScheme.onErrorContainer,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                icon: const Icon(Icons.logout_rounded),
                label: Text(l10n.signOut),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: child,
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      leading: Icon(icon, color: colorScheme.onSurfaceVariant),
      splashColor: Colors.transparent,
      title: Text(
        title,
        style: AppTextTheme.body,
      ),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle!,
              style: AppTextTheme.caption.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: colorScheme.onSurfaceVariant,
      ),
      onTap: onTap,
    );
  }
}

class _SettingsInfoRow extends StatelessWidget {
  const _SettingsInfoRow({
    required this.icon,
    required this.title,
  });

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      leading: Icon(icon, color: colorScheme.onSurfaceVariant),
      title: Text(
        title,
        style: AppTextTheme.body,
      ),
    );
  }
}

class _SectionDivider extends StatelessWidget {
  const _SectionDivider({
    required this.color,
  });

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      color: color,
    );
  }
}
