import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:my_app/app/app.dart';
import 'package:my_app/auth/auth.dart';
import 'package:my_app/auth/bloc/signout/signout_bloc.dart';
import 'package:my_app/home/bloc/inventory/inventory_bloc.dart';
import 'package:my_app/home/widgets/widgets.dart';

class InventoryTab extends StatelessWidget {
  const InventoryTab({required this.items, super.key});
  final List<ShopItem> items;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => InventoryBloc(items),
        ),
        BlocProvider(
          create: (context) => SignoutBloc(getIt<AuthService>()),
        ),
      ],
      child: const _InventoryTabView(),
    );
  }
}

class _InventoryTabView extends StatefulWidget {
  const _InventoryTabView();

  @override
  State<_InventoryTabView> createState() => _InventoryTabState();
}

class _InventoryTabState extends State<_InventoryTabView> with AutomaticKeepAliveClientMixin {
  final TextEditingController _searchController = TextEditingController();
  bool _isGridView = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      context.read<InventoryBloc>().add(SearchItemsEvent(_searchController.text));
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showFilterSheet() {
    showModalBottomSheet<ShopItem>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => BlocProvider.value(
        value: context.read<InventoryBloc>(),
        child: FilterSheet(
          initialCategoryFilter: context.read<InventoryBloc>().state.categoryFilter,
          initialBuyerFilter: context.read<InventoryBloc>().state.buyerFilter,
          onApply: (category, buyer) => context.read<InventoryBloc>().add(FilterItemsEvent(category, buyer)),
        ),
      ),
    );
  }

  void _toggleView() {
    _isGridView = !_isGridView;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colorScheme.primary, // Dynamic primary color
                  colorScheme.primaryContainer, // Lighter variant
                ],
              ),
              color: colorScheme.surface,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    BlocListener<SignoutBloc, SignoutState>(
                      listener: (context, state) {
                        if (state is SignoutSuccess) {
                          context.read<AuthBloc>().add(AuthSignedOut());
                        }
                      },
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () async {
                          final shouldSignOut = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Sign Out'),
                              content: const Text('Are you sure you want to sign out?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(false), // Cancel
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(true), // Confirm
                                  child: const Text('Sign Out'),
                                ),
                              ],
                            ),
                          );

                          if (shouldSignOut ?? false) {
                            if (!context.mounted) return;
                            context.read<SignoutBloc>().add(const SignoutSubmitted());
                          }
                        },
                        child: Row(
                          children: [
                            const CircleAvatar(
                              radius: 14,
                              backgroundImage: NetworkImage(
                                'https://cdn2.vectorstock.com/i/1000x1000/44/01/default-avatar-photo-placeholder-icon-grey-vector-38594401.jpg',
                              ),
                            ),
                            const SizedBox(width: 8),
                            BlocBuilder<AuthBloc, AuthState>(
                              builder: (context, state) {
                                if (state is Authenticated) {
                                  return Text(
                                    state.user.name ?? 'No name',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.onPrimary,
                                    ),
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 36,
                      child: SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment(
                            value: false,
                            icon: Icon(Icons.list),
                            label: Text('List'),
                          ),
                          ButtonSegment(
                            value: true,
                            icon: Icon(Icons.grid_view),
                            label: Text('Grid'),
                          ),
                        ],
                        showSelectedIcon: false,
                        selected: {_isGridView},
                        onSelectionChanged: (newSelection) => _toggleView(),
                        style: SegmentedButton.styleFrom(
                          backgroundColor: colorScheme.onPrimary.withValues(alpha: 0.1),
                          foregroundColor: colorScheme.onPrimary,
                          selectedForegroundColor: colorScheme.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 12).copyWith(bottom: 10),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 48,
                  child: Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: TextField(
                            expands: true,
                            maxLines: null,
                            textInputAction: TextInputAction.done,
                            controller: _searchController,
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                              hintText: 'Search items...',
                              prefixIcon: Icon(Icons.search, color: colorScheme.primary),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: .3),
                            ),
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
                ),
              ],
            ),
          ),
          // Items Listing
          Expanded(
            child: BlocBuilder<InventoryBloc, InventoryState>(
              buildWhen: (previous, current) => previous.filteredItems != current.filteredItems,
              builder: (context, state) {
                return RefreshIndicator(
                  onRefresh: () async {
                    context.read<InventoryBloc>().add(RefreshItemsEvent());
                    await context.read<InventoryBloc>().stream.first;
                  },
                  color: colorScheme.primary,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (Widget child, Animation<double> animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: ScaleTransition(
                          scale: animation.drive(
                            Tween<double>(begin: 0.95, end: 1).chain(
                              CurveTween(curve: Curves.easeInOut),
                            ),
                          ),
                          child: child,
                        ),
                      );
                    },
                    layoutBuilder: (currentChild, previousChildren) => currentChild!,
                    child: _isGridView
                        ? GridView.builder(
                            key: const ValueKey('grid'), // Unique key for AnimatedSwitcher
                            padding: const EdgeInsets.all(16),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: 0.75,
                            ),
                            physics: const BouncingScrollPhysics().applyTo(const AlwaysScrollableScrollPhysics()),
                            cacheExtent: 1000,
                            itemCount: state.filteredItems.length,
                            itemBuilder: (context, index) {
                              return AnimatedScale(
                                scale: 1,
                                duration: const Duration(milliseconds: 200),
                                child: GridShopItemCard(
                                  key: ValueKey(state.filteredItems[index].name),
                                  item: state.filteredItems[index],
                                  onEdit: (item) {
                                    context.pushNamed(
                                      AppRoutes.createShopItem,
                                      extra: {'existingItem': item},
                                    );
                                  },
                                ),
                              );
                            },
                          )
                        : ListView.builder(
                            key: const ValueKey('list'), // Unique key for AnimatedSwitcher
                            padding: const EdgeInsets.all(16),
                            itemCount: state.filteredItems.length,
                            physics: const BouncingScrollPhysics().applyTo(const AlwaysScrollableScrollPhysics()),
                            cacheExtent: 1000,
                            itemBuilder: (context, index) {
                              return AnimatedSlide(
                                offset: Offset(0, state.filteredItems[index].name.isNotEmpty ? 0 : 0.1),
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                                child: ShopItemCard(
                                  key: ValueKey(state.filteredItems[index].name),
                                  item: state.filteredItems[index],
                                  onEdit: (item) {
                                    context.pushNamed(
                                      AppRoutes.createShopItem,
                                      extra: {'existingItem': item},
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Helper method for consistent icon buttons
  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onPressed,
    required ColorScheme colorScheme,
    String? tooltip,
  }) {
    return SizedBox(
      height: 48,
      width: 48,
      child: Tooltip(
        message: tooltip ?? '',
        child: IconButton(
          onPressed: onPressed,
          icon: Icon(
            icon,
            color: Colors.black,
          ),
          style: IconButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildSegmentButtons({
    required IconData icon,
    required VoidCallback onPressed,
    required ColorScheme colorScheme,
  }) {
    return SizedBox(
      height: 48,
      child: SegmentedButton<bool>(
        segments: [
          ButtonSegment(
            value: false,
            icon: Icon(Icons.list, color: _isGridView ? Colors.white : null),
            label: Text('List', style: TextStyle(color: _isGridView ? Colors.white : null)),
          ),
          const ButtonSegment(
            value: true,
            icon: Icon(Icons.grid_view),
            label: Text('Grid'),
          ),
        ],
        selected: {_isGridView},
        onSelectionChanged: (newSelection) {
          _isGridView = newSelection.first;
          setState(() {});
        },
      ),
    );
  }
}

// Assuming ShopItemCard and GridShopItemCard are defined elsewhere
