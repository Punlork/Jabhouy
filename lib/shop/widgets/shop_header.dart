import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:my_app/app/app.dart';
import 'package:my_app/auth/bloc/auth_bloc.dart';
import 'package:my_app/auth/bloc/signout/signout_bloc.dart';
import 'package:my_app/l10n/l10n.dart';

class ShopHeader extends StatelessWidget {
  const ShopHeader({
    required this.onSettingsPressed,
    required this.onSearchChanged,
    required this.onFilterPressed,
    required this.searchController,
    required this.hasFilter,
    super.key,
  });
  final VoidCallback onSettingsPressed;
  final ValueChanged<String?> onSearchChanged;
  final VoidCallback onFilterPressed;
  final TextEditingController searchController;
  final bool hasFilter;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      // height: 100,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colorScheme.primary, colorScheme.primaryContainer],
        ),
      ),
      child: Column(
        children: [
          // Row(
          //   children: [
          //     const _UserProfile(),
          //     const Spacer(),
          //     _SettingsButton(onPressed: onSettingsPressed),
          //   ],
          // ),
          const SizedBox(height: 8),
          _SearchBar(
            hasFilter: hasFilter,
            controller: searchController,
            onChanged: onSearchChanged,
            onFilterPressed: onFilterPressed,
            onSettingsPressed: onSettingsPressed,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _UserProfile extends StatelessWidget {
  const _UserProfile();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () async {},
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is Authenticated) {
            return Row(
              children: [
                if (state.user.image != null)
                  ClipOval(
                    child: Image.network(
                      state.user.image!,
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                    ),
                  )
                else
                  const AppLogo(size: 40, useBg: false),
                const SizedBox(width: 8),
                Row(
                  children: [
                    Text(
                      state.user.name ?? l10n.noName,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                ),
              ],
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _SettingsButton extends StatelessWidget {
  const _SettingsButton({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

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
        icon: Icons.settings,
        color: Colors.black,
        onPressed: onPressed,
        colorScheme: colorScheme,
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
  });
  final TextEditingController controller;
  final ValueChanged<String?> onChanged;
  final VoidCallback onFilterPressed;
  final VoidCallback onSettingsPressed;
  final bool hasFilter;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    return SizedBox(
      height: 48,
      child: Row(
        children: [
          Expanded(
            child: CustomTextFormField(
              controller: controller,
              hintText: l10n.searchItems,
              labelText: '',
              prefixIcon: Icons.search,
              onChanged: onChanged,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
              action: TextInputAction.search,
              showClearButton: true,
              floatingLabelBehavior: FloatingLabelBehavior.always,
              useCustomBorder: false,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white.withOpacity(.8),
                      fontWeight: FontWeight.w300,
                    ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest.withOpacity(.3),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _SettingsButton(onPressed: onSettingsPressed),
        ],
      ),
    );
  }
}
