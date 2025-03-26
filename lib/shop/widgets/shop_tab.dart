import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_app/app/app.dart';
import 'package:my_app/l10n/l10n.dart';
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

class _ShopTabState extends State<_ShopTabView> with AutomaticKeepAliveClientMixin {
  bool _shouldRebuild(ShopState previous, ShopState current) {
    if (previous is ShopLoaded && current is ShopLoaded) {
      for (var i = 0; i < previous.asLoaded!.items.length; i++) {
        if (previous.items[i] != current.items[i]) {
          return true;
        }
      }
      return previous.searchQuery != current.searchQuery ||
          previous.categoryFilter != current.categoryFilter ||
          previous.items.length != current.items.length;
    }
    return true;
  }

  Future<void> _refreshItems() async {
    if (!mounted) return;
    context.read<ShopBloc>().add(
          ShopGetItemsEvent(
            forceRefresh: true,
            page: 1,
            limit: 10,
          ),
        );
    context.read<CategoryBloc>().add(CategoryGetEvent());
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return BlocBuilder<ShopBloc, ShopState>(
      buildWhen: _shouldRebuild,
      builder: (context, state) => switch (state) {
        ShopInitial() || ShopLoading() => CustomScrollView(
            physics: const BouncingScrollPhysics().applyTo(const AlwaysScrollableScrollPhysics()),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverGrid.builder(
                  itemCount: 6,
                  itemBuilder: (context, index) => const GridShopItemShimmer(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.8,
                  ),
                ),
              ),
            ],
          ),
        ShopLoaded(:final items) => RefreshIndicator(
            onRefresh: _refreshItems,
            child: items.isEmpty ? const EmptyView() : const ShopGridBuilder(),
          ),
        ShopError(:final message) => ErrorView(message: message),
      },
    );
  }

  @override
  bool get wantKeepAlive => true;
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
          Text(message, style: const TextStyle(fontSize: 18, color: Colors.red)),
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
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: Colors.black),
      ),
    );
  }
}
