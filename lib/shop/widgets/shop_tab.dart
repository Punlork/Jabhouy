import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:my_app/app/app.dart';
import 'package:my_app/l10n/arb/app_localizations.dart';
import 'package:my_app/shop/shop.dart';

class ShopTab extends StatelessWidget {
  const ShopTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const _ShopTabView();
  }
}

class _ShopTabView extends StatefulWidget {
  const _ShopTabView();

  @override
  State<_ShopTabView> createState() => _ShopTabState();
}

class _ShopTabState extends State<_ShopTabView>
    with AutomaticKeepAliveClientMixin {
  bool _shouldRebuild(ShopState previous, ShopState current) =>
      previous != current;

  Future<void> _refreshItems() async {
    if (!mounted) return;
    final currentState = context.read<ShopBloc>().state.asLoaded;
    context.read<ShopBloc>().add(
          ShopGetItemsEvent(
            forceRefresh: true,
            page: 1,
            limit: currentState?.pagination.limit ?? 100,
            searchQuery: currentState?.searchQuery,
            categoryFilter: currentState?.categoryFilter,
          ),
        );
    context.read<CategoryBloc>().add(CategoryGetEvent());
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Stack(
      children: [
        BlocBuilder<ShopBloc, ShopState>(
          buildWhen: _shouldRebuild,
          builder: (context, state) => switch (state) {
            ShopInitial() || ShopLoading() => const ShopGridLoading(),
            ShopLoaded(
              :final items,
              :final pagination,
              :final isFiltering,
              :final isOffline,
              :final syncMessage,
            ) =>
              RefreshIndicator(
                onRefresh: _refreshItems,
                child: Column(
                  children: [
                    if (syncMessage != null)
                      _SyncStatusBanner(
                        message: syncMessage,
                        isOffline: isOffline,
                      ),
                    Expanded(
                      child: Builder(
                        builder: (context) {
                          if ((isFiltering ?? false) && items.isEmpty) {
                            return const ShopGridLoading();
                          }
                          if (items.isEmpty) {
                            return const EmptyView();
                          }
                          return Stack(
                            children: [
                              ShopGridBuilder(
                                items: items,
                                pagination: pagination,
                              ),
                              if (isFiltering ?? false)
                                const Positioned(
                                  top: 52,
                                  left: 16,
                                  right: 16,
                                  child: LinearProgressIndicator(),
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ShopError(:final message) => ErrorView(message: message),
          },
        ),
        const CategoryChips(),
      ],
    );
  }

  @override
  bool get wantKeepAlive => true;
}

class _SyncStatusBanner extends StatelessWidget {
  const _SyncStatusBanner({
    required this.message,
    required this.isOffline,
  });

  final String message;
  final bool isOffline;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 52, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            isOffline ? Icons.cloud_off_rounded : Icons.sync_rounded,
            size: 18,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class ShopGridLoading extends StatelessWidget {
  const ShopGridLoading({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final crossAxisCount = _resolveCrossAxisCount(context);

    return CustomScrollView(
      physics: const BouncingScrollPhysics()
          .applyTo(const AlwaysScrollableScrollPhysics()),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16).copyWith(
            bottom: 52,
            top: 52,
          ),
          sliver: SliverAlignedGrid.count(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            itemCount: 6,
            itemBuilder: (context, index) => const GridShopItemShimmer(),
          ),
        ),
      ],
    );
  }

  int _resolveCrossAxisCount(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    if (width > 600) {
      return 3;
    }

    return 2;
  }
}

class ErrorView extends StatelessWidget {
  const ErrorView({required this.message, super.key});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
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
    );
  }
}

class ItemCount extends StatelessWidget {
  const ItemCount({required this.counts, super.key});
  final int counts;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Positioned(
      top: 150,
      right: 40,
      child: Text(
        l10n.itemCount(counts.toString()),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: Colors.black,
        ),
      ),
    );
  }
}
