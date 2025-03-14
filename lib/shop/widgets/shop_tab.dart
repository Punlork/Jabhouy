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
  Future<void> _refreshItems() async {
    context.read<ShopBloc>().add(
          ShopGetItemsEvent(
            forceRefresh: true,
            page: 1,
            pageSize: 10,
          ),
        );
    context.read<CategoryBloc>().add(CategoryGetEvent());
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final counts = context.watch<ShopBloc>().state.asLoaded?.pagination.total ?? 0;

    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              ShopList(onRefresh: _refreshItems),
            ],
          ),
          ItemCount(counts: counts),
        ],
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}

class ShopList extends StatelessWidget {
  const ShopList({required this.onRefresh, super.key});
  final Future<void> Function() onRefresh;

  bool _shouldRebuild(ShopState previous, ShopState current) {
    if (previous is ShopLoaded && current is ShopLoaded) {
      return previous.items != current.items;
    }
    return previous.runtimeType != current.runtimeType;
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: BlocBuilder<ShopBloc, ShopState>(
        buildWhen: _shouldRebuild,
        builder: (context, state) => switch (state) {
          ShopInitial() || ShopLoading() => const Center(child: CustomLoading()),
          ShopLoaded(:final items) => ItemsView(items: items, onRefresh: onRefresh),
          ShopError(:final message) => ErrorView(message: message),
        },
      ),
    );
  }
}

class ItemsView extends StatelessWidget {
  const ItemsView({required this.items, required this.onRefresh, super.key});
  final List<ShopItemModel> items;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (items.isEmpty) return const EmptyView();

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: colorScheme.primary,
      child: const ShopGridBuilder(),
    );
  }
}

// Empty View Widget
class EmptyView extends StatelessWidget {
  const EmptyView({super.key});

  @override
  Widget build(BuildContext context) {
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
