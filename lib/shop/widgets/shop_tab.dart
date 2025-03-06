import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:my_app/app/app.dart';
import 'package:my_app/auth/auth.dart';
import 'package:my_app/auth/bloc/signout/signout_bloc.dart';
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

class _ShopTabState extends State<_ShopTabView> with AutomaticKeepAliveClientMixin {
  final _searchController = TextEditingController();
  bool _isGridView = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    context.read<ShopBloc>().add(ShopGetItemsEvent());
    super.initState();
    _searchController.addListener(() {
      // context.read<ShopBloc>().add(SearchItemsEvent(_searchController.text));
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showFilterSheet() {
    // showModalBottomSheet<ShopItem>(
    //   context: context,
    //   shape: const RoundedRectangleBorder(
    //     borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    //   ),
    //   builder: (_) => BlocProvider.value(
    //     value: context.read<ShopBloc>(),
    //     child: FilterSheet(
    //       initialCategoryFilter: context.read<ShopBloc>().state.categoryFilter,
    //       initialBuyerFilter: context.read<ShopBloc>().state.buyerFilter,
    //       onApply: (category, buyer) => context.read<ShopBloc>().add(
    //             FilterItemsEvent(category, buyer),
    //           ),
    //     ),
    //   ),
    // );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final colorScheme = Theme.of(context).colorScheme;

    final counts = context.watch<ShopBloc>().state.asLoaded?.items.length;

    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colorScheme.primary,
                      colorScheme.primaryContainer,
                    ],
                  ),
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
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () async {},
                          child: Row(
                            children: [
                              const AppLogo(
                                size: 40,
                                useBg: false,
                              ),
                              const SizedBox(width: 8),
                              BlocBuilder<AuthBloc, AuthState>(
                                builder: (context, state) {
                                  if (state is Authenticated) {
                                    return StreamBuilder<Object>(
                                      stream: null,
                                      builder: (context, snapshot) {
                                        return Row(
                                          children: [
                                            Text(
                                              state.user.name ?? 'No name',
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: colorScheme.onPrimary,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                          ],
                                        );
                                      },
                                    );
                                  }
                                  return const SizedBox.shrink();
                                },
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
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
                            onSelectionChanged: (newSelection) {
                              setState(() => _isGridView = newSelection.first);
                            },
                            style: SegmentedButton.styleFrom(
                              backgroundColor: colorScheme.onPrimary.withValues(alpha: .1),
                              foregroundColor: colorScheme.onPrimary,
                              selectedForegroundColor: colorScheme.primary,
                              padding: const EdgeInsets.symmetric(horizontal: 12).copyWith(bottom: 10),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        MultiBlocListener(
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
                                  showSuccessSnackBar(context, 'Signout successful');
                                  context.goNamed(AppRoutes.signin);
                                }
                              },
                            ),
                          ],
                          child: _buildIconButton(
                            icon: Icons.logout,
                            color: Colors.red,
                            onPressed: () async {
                              final shouldSignOut = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Sign Out'),
                                  content: const Text('Are you sure you want to sign out?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, false),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, true),
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
                            colorScheme: colorScheme,
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
                            child: CustomTextFormField(
                              controller: _searchController,
                              hintText: 'Search items...',
                              labelText: '', // Adding a label for clarity, optional
                              prefixIcon: Icons.search,
                              action: TextInputAction.search, // Optional: adds search action to keyboard
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
                    ),
                  ],
                ),
              ),
              // Items Listing
              buildShopList(
                context,
                isGridView: _isGridView,
              ),
            ],
          ),
          Positioned(
            top: 150,
            right: 40,
            child: Text(
              'Counts: $counts',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildShopList(
    BuildContext context, {
    required bool isGridView,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Expanded(
      child: BlocBuilder<ShopBloc, ShopState>(
        buildWhen: (previous, current) {
          if (previous is ShopLoaded && current is ShopLoaded) {
            return previous.items != current.items;
          }
          return previous.runtimeType != current.runtimeType;
        },
        builder: (context, state) {
          return switch (state) {
            ShopInitial() || ShopLoading() => const Center(child: CircularProgressIndicator()),
            ShopLoaded(:final items) => items.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No items found',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () async {
                      context.read<ShopBloc>().add(ShopGetItemsEvent(forceRefresh: true));
                      // await context.read<ShopBloc>().stream.firstWhere((state) => state is! ShopLoading);
                    },
                    color: colorScheme.primary,
                    child: AnimatedSwitcher(
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
                      child: isGridView
                          ? GridView.builder(
                              key: const ValueKey('grid'),
                              padding: const EdgeInsets.all(16),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                childAspectRatio: 0.75,
                              ),
                              physics: const BouncingScrollPhysics().applyTo(const AlwaysScrollableScrollPhysics()),
                              cacheExtent: 1000,
                              itemCount: items.length,
                              itemBuilder: (context, index) {
                                return AnimatedScale(
                                  scale: 1,
                                  duration: const Duration(milliseconds: 200),
                                  child: GridShopItemCard(
                                    key: ValueKey(items[index].name),
                                    item: items[index],
                                    onEdit: (item) => showShopItemDetailSheet(
                                      context: context,
                                      item: item,
                                      onEdit: () {
                                        context
                                          ..pop()
                                          ..pushNamed(
                                            AppRoutes.createShopItem,
                                            extra: {
                                              'existingItem': item,
                                              'bloc': context.read<ShopBloc>(),
                                            },
                                          );
                                      },
                                      onDelete: () => context.read<ShopBloc>().add(
                                            ShopDeleteItemEvent(
                                              body: item,
                                            ),
                                          ),
                                    ),
                                  ),
                                );
                              },
                            )
                          : ListView.builder(
                              key: const ValueKey('list'),
                              padding: const EdgeInsets.all(16),
                              itemCount: items.length,
                              physics: const BouncingScrollPhysics().applyTo(const AlwaysScrollableScrollPhysics()),
                              cacheExtent: 1000,
                              itemBuilder: (context, index) {
                                return AnimatedSlide(
                                  offset: Offset(0, items[index].name.isNotEmpty ? 0 : 0.1),
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                  child: ShopItemCard(
                                    onDelete: (_) async {
                                      LoadingOverlay.show();
                                      await Future<void>.delayed(const Duration(seconds: 2));
                                      LoadingOverlay.hide();
                                    },
                                    key: ValueKey(items[index].name),
                                    item: items[index],
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
                  ),
            ShopError(:final message) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      message,
                      style: const TextStyle(fontSize: 18, color: Colors.red),
                    ),
                  ],
                ),
              ),
          };
        },
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
          icon: Icon(
            icon,
            color: color ?? Colors.black,
          ),
          style: IconButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 2,
          ),
        ),
      ),
    );
  }
}

// Assuming ShopItemCard and GridShopItemCard are defined elsewhere
