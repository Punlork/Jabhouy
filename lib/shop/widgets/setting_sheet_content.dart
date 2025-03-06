// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_app/app/app.dart';
import 'package:my_app/l10n/l10n.dart';

class SettingsSheet extends StatelessWidget {
  const SettingsSheet({
    required this.onSignout,
    super.key,
  });
  final VoidCallback onSignout;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.settings,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.logout, color: Colors.red),
            title: Text(l10n.signOut),
            onTap: () async {
              Navigator.pop(context);
              final shouldSignOut = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(l10n.signOut),
                  content: Text(l10n.confirmSignOut),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
                    TextButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.signOut)),
                  ],
                ),
              );

              if (shouldSignOut ?? false) {
                onSignout();
              }
            },
          ),
          BlocBuilder<AppBloc, AppState>(
            builder: (context, state) {
              final currentLocale = state.locale.languageCode;
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.language),
                title: Text(l10n.switchLanguage),
                subtitle: Text(currentLocale == 'en' ? l10n.languageEnglish : l10n.languageKhmer),
                onTap: () {
                  context.read<AppBloc>().add(SwitchLanguage(currentLocale));
                  Navigator.pop(context);
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
