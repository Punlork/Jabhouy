import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:jabhouy/app/app.dart';
import 'package:jabhouy/auth/auth.dart';
import 'package:jabhouy/customer/customer.dart';
import 'package:jabhouy/income/income.dart';
import 'package:jabhouy/membership/membership.dart';
import 'package:jabhouy_core/jabhouy_core.dart';
import 'package:jabhouy_l10n/jabhouy_l10n.dart';
import 'package:jabhouy_shop/jabhouy_shop.dart';
import 'package:jabhouy_ui/jabhouy_ui.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  int _diagnosticsTapCount = 0;
  late final Future<String> _appVersionFuture;
  final _isIncomeEnabled = getIt<FeatureFlags>().isEnabled(Feature.income);
  final _isDiagnosticsEnabled = getIt<FeatureFlags>().isEnabled(Feature.diagnostics);

  @override
  void initState() {
    super.initState();
    _appVersionFuture = _loadAppVersion();
  }

  void _handleHiddenDiagnosticsTap() {
    if (!_isDiagnosticsEnabled) {
      return;
    }

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
        if (_isIncomeEnabled) 'incomeBloc': context.read<IncomeBloc>(),
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

  void _openPriceSettings() {
    context.pushNamed(
      AppRoutes.priceSettings,
      extra: {'priceSettingsCubit': context.read<PriceSettingsCubit>()},
    );
  }

  void _openCategoriesUnits() {
    context.pushNamed(
      AppRoutes.categoriesUnits,
      extra: {'categoriesCubit': context.read<CategoriesCubit>()},
    );
  }

  /// `$1 = 4,000 ៛ · លក់ដុំ · ដើម`: the rate and the extra prices in use.
  String _pricesSummary(AppLocalizations l10n, PriceSettings s) => [
        l10n.settingsRateFormat(Money(s.khrPerUsd, Currency.khr).formatNumber()),
        if (s.useWholesale) l10n.priceWholesaleLabel,
        if (s.useCost) l10n.priceCostShort,
      ].join(' · ');

  String _roleLabel(AppLocalizations l10n, MemberRole? role) => switch (role) {
        MemberRole.owner => l10n.roleOwner,
        MemberRole.editor => l10n.roleEditor,
        MemberRole.viewer || null => l10n.roleViewer,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.tokens;
    final shop = getIt<CurrentShop>();
    final authState = context.watch<AuthBloc>().state;
    final user = authState is Authenticated ? authState.user : null;
    final name = user?.name ?? user?.username ?? '';
    final shopName = shop.shops
        .where((s) => s.id == shop.id)
        .map((s) => s.name)
        .firstOrNull;

    return Scaffold(
      backgroundColor: t.bg,
      appBar: AppBar(
        centerTitle: false,
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: GestureDetector(
          onTap: _handleHiddenDiagnosticsTap,
          behavior: HitTestBehavior.opaque,
          child: Text(l10n.settings),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            _ProfileCard(
              name: name,
              subtitle: [
                if (shopName != null && shopName.isNotEmpty) shopName,
                _roleLabel(l10n, shop.role),
              ].join(' · '),
              onTap: () => context.pushNamed(AppRoutes.profile),
            ),
            const SizedBox(height: 22),
            _Section(
              title: l10n.shop,
              footnote: shop.role == MemberRole.owner
                  ? null
                  : l10n.settingsOwnerOnly,
              rows: [
                BlocBuilder<PriceSettingsCubit, PriceSettings?>(
                  builder: (context, prices) => _Row(
                    icon: Icons.sell_outlined,
                    title: l10n.settingsPricesCurrency,
                    subtitle:
                        prices == null ? null : _pricesSummary(l10n, prices),
                    onTap: _openPriceSettings,
                  ),
                ),
                BlocBuilder<CategoriesCubit, List<ItemCategory>?>(
                  builder: (context, categories) => _Row(
                    icon: Icons.category_outlined,
                    title: l10n.settingsCategoriesUnits,
                    subtitle: categories == null
                        ? null
                        : l10n.categoriesCount(categories.length),
                    onTap: _openCategoriesUnits,
                  ),
                ),
                _Row(
                  icon: Icons.people_outline_rounded,
                  title: l10n.customers,
                  onTap: () => context.pushNamed(
                    AppRoutes.customer,
                    extra: {'customerBloc': context.read<CustomerBloc>()},
                  ),
                ),
              ],
            ),
            // The main/sub device role only decides which phone captures
            // bank notifications, so it goes with the income feature.
            if (_isIncomeEnabled) ...[
              const SizedBox(height: 22),
              BlocBuilder<AppBloc, AppState>(
                builder: (context, state) => _DeviceRoleCard(
                  isMainDevice: state.deviceRole.isMain,
                  onToggle: () => _toggleDeviceRole(
                    isMainDevice: state.deviceRole.isMain,
                    l10n: l10n,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 22),
            BlocBuilder<AppBloc, AppState>(
              builder: (context, state) => _Section(
                title: l10n.settingsAppSection,
                rows: [
                  _Row(
                    icon: Icons.language_rounded,
                    title: l10n.settingsLanguage,
                    value: state.locale.languageCode == 'en'
                        ? l10n.languageEnglish
                        : l10n.languageKhmer,
                    onTap: () => context.read<AppBloc>().add(
                          SwitchLanguage(state.locale.languageCode),
                        ),
                  ),
                  _Row(
                    icon: state.isDarkMode
                        ? Icons.dark_mode_outlined
                        : Icons.light_mode_outlined,
                    title: l10n.settingsAppearance,
                    subtitle:
                        state.isDarkMode ? l10n.darkModeOn : l10n.darkModeOff,
                    trailing: Switch.adaptive(
                      value: state.isDarkMode,
                      onChanged: (value) => context
                          .read<AppBloc>()
                          .add(SwitchThemeMode(isDarkMode: value)),
                    ),
                    onTap: () => context.read<AppBloc>().add(
                          SwitchThemeMode(isDarkMode: !state.isDarkMode),
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            Material(
              color: t.surface,
              borderRadius: BorderRadius.circular(AppSizes.radiusCard),
              child: InkWell(
                onTap: () => _confirmSignOut(l10n),
                borderRadius: BorderRadius.circular(AppSizes.radiusCard),
                child: SizedBox(
                  height: 52,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.logout_rounded, color: t.dangerText, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        l10n.signOut,
                        style: AppTextTheme.body.copyWith(
                          color: t.dangerText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            FutureBuilder<String>(
              future: _appVersionFuture,
              builder: (context, snapshot) => Text(
                l10n.appVersion(snapshot.data ?? '--'),
                textAlign: TextAlign.center,
                style: AppTextTheme.hint.copyWith(color: t.textMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The signed-in user: initial, name, Shop and role (canvas ១២).
class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.name,
    required this.subtitle,
    required this.onTap,
  });

  final String name;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final letter = name.isEmpty ? '' : String.fromCharCode(name.runes.first);
    return Material(
      color: t.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: t.textPrimary,
                child: Text(
                  letter,
                  style: AppTextTheme.pageTitle.copyWith(color: t.onPrimary),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: AppTextTheme.body.copyWith(
                        color: t.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: AppTextTheme.hint.copyWith(color: t.textMuted),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: t.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

/// A titled group of rows on one white card, with an optional note.
class _Section extends StatelessWidget {
  const _Section({required this.title, required this.rows, this.footnote});

  final String title;
  final List<Widget> rows;
  final String? footnote;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
          child: Text(
            title,
            style: AppTextTheme.label.copyWith(
              color: t.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Material(
          color: t.surface,
          clipBehavior: Clip.antiAlias,
          borderRadius: BorderRadius.circular(AppSizes.radiusCard),
          child: Column(
            children: [
              for (final (i, row) in rows.indexed) ...[
                if (i > 0) Divider(height: 1, color: t.divider),
                row,
              ],
            ],
          ),
        ),
        if (footnote != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
            child: Text(
              footnote!,
              style: AppTextTheme.hint.copyWith(color: t.textMuted),
            ),
          ),
      ],
    );
  }
}

/// Icon tile, title and subtitle, then a value or a chevron.
class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.value,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? value;
  final Widget? trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: t.surfaceSubtle,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: t.textPrimary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextTheme.body.copyWith(
                        color: t.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: AppTextTheme.hint.copyWith(color: t.textMuted),
                      ),
                  ],
                ),
              ),
              if (value != null)
                Text(
                  value!,
                  style: AppTextTheme.label.copyWith(color: t.textMuted),
                ),
              trailing ?? Icon(Icons.chevron_right_rounded, color: t.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

/// Which phone captures bank notifications (income only).
class _DeviceRoleCard extends StatelessWidget {
  const _DeviceRoleCard({required this.isMainDevice, required this.onToggle});

  final bool isMainDevice;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final t = context.tokens;
    final muted = AppTextTheme.hint.copyWith(color: t.textMuted);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.deviceRole,
            style: AppTextTheme.body.copyWith(
              color: t.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isMainDevice
                ? l10n.deviceRoleMainDescription
                : l10n.deviceRoleSubDescription,
            style: muted,
          ),
          const SizedBox(height: 8),
          Text(l10n.singleMainDeviceHint, style: muted),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: onToggle,
            child: Text(
              isMainDevice ? l10n.releaseMainDevice : l10n.setAsMainDevice,
            ),
          ),
        ],
      ),
    );
  }
}
