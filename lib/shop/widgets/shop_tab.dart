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
  bool _shouldRebuild(ShopState previous, ShopState current) {
    if (previous.runtimeType != current.runtimeType) return true;
    if (previous is ShopLoaded && current is ShopLoaded) {
      return previous.items.length != current.items.length ||
          previous.searchQuery != current.searchQuery ||
          previous.itemCategories != current.itemCategories ||
          previous.isOffline != current.isOffline ||
          previous.syncMessage != current.syncMessage ||
          previous.isFiltering != current.isFiltering;
    }
    return true;
  }

  Future<void> _refreshItems() async {
    if (!mounted) return;
    context.read<ShopBloc>().add(
          ShopGetItemsEvent(
            forceRefresh: true,
            page: 1,
            limit: 100,
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
                          if (isFiltering != null && isFiltering) {
                            return const ShopGridLoading();
                          }
                          if (items.isEmpty) {
                            return const EmptyView();
                          }
                          return ShopGridBuilder(
                            items: items,
                            pagination: pagination,
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
    return CustomScrollView(
      physics: const BouncingScrollPhysics()
          .applyTo(const AlwaysScrollableScrollPhysics()),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16).copyWith(
            bottom: 52,
          ),
          sliver: SliverToBoxAdapter(
            child: MasonryGridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 6,
              itemBuilder: (context, index) => const GridShopItemShimmer(),
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              padding: EdgeInsets.zero,
              gridDelegate: SliverSimpleGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
              ),
            ),
          ),
        ),
      ],
    );
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
