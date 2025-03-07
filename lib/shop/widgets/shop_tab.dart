import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:my_app/app/app.dart';
import 'package:my_app/auth/auth.dart';
import 'package:my_app/auth/bloc/signout/signout_bloc.dart';
import 'package:my_app/l10n/l10n.dart';
import 'package:my_app/shop/shop.dart';

class ShopTab extends StatelessWidget {
  const ShopTab({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => SignoutBloc(getIt<AuthService>()),
        ),
      ],
      child: const _ShopTabView(),
    );
  }
}

class _ShopTabView extends StatefulWidget {
  const _ShopTabView();

  @override
  State<_ShopTabView> createState() => _ShopTabState();
}

class _ShopTabState extends State<_ShopTabView> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<ShopBloc>().add(ShopGetItemsEvent());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String? value) {
    context.read<ShopBloc>().add(ShopGetItemsEvent(searchQuery: value));
  }

  void _showFilterSheet() {
    // Uncomment and implement if needed
    // showModalBottomSheet<ShopItem>(
    //   context: context,o
    //   shape: const RoundedRectangleBorder(
    //     borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    //   ),~
    //   builder: (_) => BlocProvider.value(
    //     value: context.read<ShopBloc>(),
    //     child: FilterSheet(
    //       initialCategoryFilter: context.read<ShopBloc>().state.categoryFilter,
    //       initialBuyerFilter: context.read<ShopBloc>().state.buyerFilter,
    //       onApply: (category, buyer) => context.read<ShopBloc>().add(FilterItemsEvent(category, buyer)),
    //     ),
    //   ),
    // );
  }

  void _showSettingsSheet(BuildContext context, VoidCallback onSignout) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SettingsSheet(onSignout: onSignout),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final counts = context.watch<ShopBloc>().state.asLoaded?.pagination.total ?? 0;

    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              _buildHeader(context),
              _buildShopList(context),
            ],
          ),
          _buildItemCount(context, counts, l10n),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colorScheme.primary, colorScheme.primaryContainer],
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: .1), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              _buildUserProfile(context),
              const Spacer(),
              _buildViewToggle(colorScheme, l10n),
              const SizedBox(width: 8),
              _buildSettingsButton(context, colorScheme),
            ],
          ),
          const SizedBox(height: 8),
          _buildSearchBar(context, colorScheme, l10n),
        ],
      ),
    );
  }

  Widget _buildUserProfile(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () async {},
      child: Row(
        children: [
          const AppLogo(size: 40, useBg: false),
          const SizedBox(width: 8),
          BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              if (state is Authenticated) {
                return Row(
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
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildViewToggle(ColorScheme colorScheme, AppLocalizations l10n) {
    return BlocBuilder<AppBloc, AppState>(
      builder: (context, state) {
        return SizedBox(
          height: 36,
          child: SegmentedButton<bool>(
            segments: [
              ButtonSegment(value: false, icon: const Icon(Icons.list), label: Text(l10n.list)),
              ButtonSegment(value: true, icon: const Icon(Icons.grid_view), label: Text(l10n.grid)),
            ],
            showSelectedIcon: false,
            selected: {state.isGridView},
            onSelectionChanged: (newSelection) {
              context.read<AppBloc>().add(SwitchViewMode(isGridView: newSelection.first));
            },
            style: SegmentedButton.styleFrom(
              backgroundColor: colorScheme.onPrimary.withValues(alpha: .1),
              foregroundColor: colorScheme.onPrimary,
              selectedForegroundColor: colorScheme.primary,
              padding: const EdgeInsets.symmetric(horizontal: 12).copyWith(bottom: 10),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSettingsButton(BuildContext context, ColorScheme colorScheme) {
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
      child: _buildIconButton(
        icon: Icons.settings,
        color: Colors.black,
        onPressed: () => _showSettingsSheet(
          context,
          () => context.read<SignoutBloc>().add(const SignoutSubmitted()),
        ),
        colorScheme: colorScheme,
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context, ColorScheme colorScheme, AppLocalizations l10n) {
    return SizedBox(
      height: 48,
      child: Row(
        children: [
          Expanded(
            child: CustomTextFormField(
              controller: _searchController,
              hintText: l10n.searchItems,
              labelText: '',
              prefixIcon: Icons.search,
              onChanged: _onSearchChanged,
              action: TextInputAction.search,
              showClearButton: true,
              floatingLabelBehavior: FloatingLabelBehavior.always,
              useCustomBorder: false,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white.withValues(alpha: .8),
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
                fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: .3),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _buildIconButton(
            icon: Icons.filter_list,
            onPressed: _showFilterSheet,
            colorScheme: colorScheme,
          ),
        ],
      ),
    );
  }

  Widget _buildShopList(BuildContext context) {
    return Expanded(
      child: BlocBuilder<ShopBloc, ShopState>(
        buildWhen: _shouldRebuild,
        builder: (context, state) => switch (state) {
          ShopInitial() || ShopLoading() => const Center(child: CustomLoading()),
          ShopLoaded(:final items) => _buildItemsView(context, items),
          ShopError(:final message) => _buildErrorView(context, message),
        },
      ),
    );
  }

  bool _shouldRebuild(ShopState previous, ShopState current) {
    if (previous is ShopLoaded && current is ShopLoaded) {
      return previous.items != current.items;
    }
    return previous.runtimeType != current.runtimeType;
  }

  Widget _buildItemsView(BuildContext context, List<ShopItemModel> items) {
    final colorScheme = Theme.of(context).colorScheme;
    if (items.isEmpty) return _buildEmptyView();

    return RefreshIndicator(
      onRefresh: () => _refreshItems(context),
      color: colorScheme.primary,
      child: BlocBuilder<AppBloc, AppState>(
        builder: (context, appState) {
          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: animation.drive(
                  Tween<double>(begin: 0.95, end: 1).chain(CurveTween(curve: Curves.easeInOut)),
                ),
                child: child,
              ),
            ),
            child: appState.isGridView ? const ShopGridBuilder() : _buildListView(context, items),
          );
        },
      ),
    );
  }

  Widget _buildEmptyView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('No items found', style: TextStyle(fontSize: 18, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildListView(BuildContext context, List<ShopItemModel> items) {
    return ListView.builder(
      key: const ValueKey('list'),
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      physics: const BouncingScrollPhysics().applyTo(const AlwaysScrollableScrollPhysics()),
      cacheExtent: 1000,
      itemBuilder: (context, index) => AnimatedSlide(
        offset: Offset(0, items[index].name.isNotEmpty ? 0 : 0.1),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        child: ShopItemCard(
          key: ValueKey(items[index].name),
          item: items[index],
          onDelete: (_) async {
            LoadingOverlay.show();
            await Future<void>.delayed(const Duration(seconds: 2));
            LoadingOverlay.hide();
          },
          onEdit: (item) => context.pushNamed(AppRoutes.createShopItem, extra: {'existingItem': item}),
        ),
      ),
    );
  }

  Widget _buildErrorView(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(fontSize: 18, color: Colors.red)),
        ],
      ),
    );
  }

  Widget _buildItemCount(BuildContext context, int counts, AppLocalizations l10n) {
    return Positioned(
      top: 150,
      right: 40,
      child: Text(
        l10n.itemCount(counts.toString()),
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: Colors.black),
      ),
    );
  }

  Future<void> _refreshItems(BuildContext context) async {
    context.read<ShopBloc>().add(
          ShopGetItemsEvent(
            forceRefresh: true,
            page: 1,
            pageSize: 10,
          ),
        );
  }

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onPressed,
    required ColorScheme colorScheme,
    String? tooltip,
    Color? color,
  }) {
    return SizedBox(
      height: 48,
      width: 48,
      child: Tooltip(
        message: tooltip ?? '',
        child: IconButton(
          onPressed: onPressed,
          icon: Icon(icon, color: color ?? Colors.black),
          style: IconButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 2,
          ),
        ),
      ),
    );
  }
}
