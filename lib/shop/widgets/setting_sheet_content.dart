import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:my_app/app/app.dart';
import 'package:my_app/customer/customer.dart';
import 'package:my_app/l10n/arb/app_localizations.dart';
import 'package:my_app/shop/shop.dart';

class SettingsSheet extends StatelessWidget {
  const SettingsSheet({
    required this.onSignout,
    super.key,
  });
  final VoidCallback onSignout;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.settings,
            style: AppTextTheme.headline.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.person, color: colorScheme.onSurfaceVariant),
            title: Text(
              l10n.profile,
              style: AppTextTheme.body,
            ),
            onTap: () {
              context.goNamed(
                AppRoutes.profile,
              );
              Navigator.pop(context);
            },
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.category, color: colorScheme.onSurfaceVariant),
            title: Text(
              l10n.category,
              style: AppTextTheme.body,
            ),
            onTap: () {
              context.goNamed(
                AppRoutes.category,
                extra: {
                  'shop': context.read<ShopBloc>(),
                  'category': context.read<CategoryBloc>(),
                },
              );
              Navigator.pop(context);
            },
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.people, color: colorScheme.onSurfaceVariant),
            title: Text(
              l10n.customers,
              style: AppTextTheme.body,
            ),
            onTap: () {
              context.goNamed(
                AppRoutes.customer,
                extra: {
                  'customerBloc': context.read<CustomerBloc>(),
                },
              );
              Navigator.pop(context);
            },
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.logout, color: colorScheme.onSurfaceVariant),
            title: Text(
              l10n.signOut,
              style: AppTextTheme.body,
            ),
            onTap: () async {
              Navigator.pop(context);
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

              if (shouldSignOut ?? false) {
                onSignout();
              }
            },
          ),
          Divider(color: colorScheme.outlineVariant),
          BlocBuilder<AppBloc, AppState>(
            builder: (context, state) {
              return SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                secondary: Icon(
                  state.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                ),
                title: Text(
                  l10n.darkMode,
                  style: AppTextTheme.body,
                ),
                subtitle: Text(
                  state.isDarkMode ? l10n.darkModeOn : l10n.darkModeOff,
                  style: AppTextTheme.caption,
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
          const SizedBox(height: 8),
          BlocBuilder<AppBloc, AppState>(
            builder: (context, state) {
              final currentLocale = state.locale.languageCode;
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.language),
                title: Text(
                  l10n.switchLanguage,
                  style: AppTextTheme.body,
                ),
                subtitle: Text(
                  currentLocale == 'en'
                      ? l10n.languageEnglish
                      : l10n.languageKhmer,
                  style: AppTextTheme.caption,
                ),
                onTap: () {
                  context.read<AppBloc>().add(SwitchLanguage(currentLocale));
                  Navigator.pop(context);
                },
              );
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
