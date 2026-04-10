import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:my_app/app/app.dart';
import 'package:my_app/auth/bloc/auth_bloc.dart';
import 'package:my_app/auth/bloc/signout/signout_bloc.dart';
import 'package:my_app/l10n/arb/app_localizations.dart';

class ShopHeader extends StatelessWidget {
  const ShopHeader({
    required this.onSettingsPressed,
    required this.onSearchChanged,
    required this.onFilterPressed,
    required this.searchController,
    required this.hasFilter,
    this.searchHintText,
    super.key,
  });
  final VoidCallback onSettingsPressed;
  final ValueChanged<String?> onSearchChanged;
  final VoidCallback onFilterPressed;
  final TextEditingController searchController;
  final bool hasFilter;
  final String? searchHintText;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      child: Column(
        children: [
          _SearchBar(
            hasFilter: hasFilter,
            controller: searchController,
            onChanged: onSearchChanged,
            onFilterPressed: onFilterPressed,
            onSettingsPressed: onSettingsPressed,
            searchHintText: searchHintText,
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _SettingsButton extends StatelessWidget {
  const _SettingsButton({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<SignoutBloc, SignoutState>(
          listener: (context, state) {
            if (state is SignoutSuccess) {
              context.read<AuthBloc>().add(AuthSignedOut());
            }
          },
        ),
        BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is Unauthenticated) {
              final l10n = AppLocalizations.of(context);
              showSuccessSnackBar(context, l10n.signoutSuccessful);
              context.goNamed(AppRoutes.signin);
            }
          },
        ),
      ],
      child: IconButtonWidget(
        svgAsset: AppAssets.actionSettings,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        tooltip: AppLocalizations.of(context).settings,
        onPressed: onPressed,
        colorScheme: Theme.of(context).colorScheme,
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.onChanged,
    required this.onFilterPressed,
    required this.onSettingsPressed,
    required this.hasFilter,
    this.searchHintText,
  });
  final TextEditingController controller;
  final ValueChanged<String?> onChanged;
  final VoidCallback onFilterPressed;
  final VoidCallback onSettingsPressed;
  final bool hasFilter;
  final String? searchHintText;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    return SizedBox(
      height: 40,
      child: Row(
        children: [
          Expanded(
            child: CustomTextFormField(
              controller: controller,
              hintText: searchHintText ?? l10n.searchItems,
              labelText: '',
              prefixIcon: Icons.search,
              onChanged: onChanged,
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 16,
              ),
              action: TextInputAction.search,
              showClearButton: true,
              floatingLabelBehavior: FloatingLabelBehavior.always,
              useCustomBorder: false,
              decoration: InputDecoration(
                prefixIconColor: colorScheme.onSurfaceVariant,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w300,
                    ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: colorScheme.surfaceContainerHigh,
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButtonWidget(
            svgAsset: AppAssets.actionFilter,
            color: hasFilter
                ? colorScheme.onPrimaryContainer
                : colorScheme.onSurfaceVariant,
            backgroundColor: hasFilter
                ? colorScheme.primaryContainer
                : colorScheme.surfaceContainerHigh,
            tooltip: l10n.filterItems,
            onPressed: onFilterPressed,
            colorScheme: colorScheme,
          ),
          const SizedBox(width: 8),
          _SettingsButton(onPressed: onSettingsPressed),
        ],
      ),
    );
  }
}
