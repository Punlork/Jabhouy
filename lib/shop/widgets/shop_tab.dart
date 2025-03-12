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
    context.read<CategoryBloc>().add(CategoryGetEvent());
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
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => BlocProvider.value(
        value: context.read<ShopBloc>(),
        child: BlocProvider.value(
          value: context.read<CategoryBloc>(),
          child: FilterSheet(
            initialCategoryFilter: context.read<ShopBloc>().state.asLoaded?.categoryFilter,
            onApply: (category) => context.read<ShopBloc>().add(ShopGetItemsEvent(categoryFilter: category)),
          ),
        ),
      ),
    );
  }

  void _showSettingsSheet(VoidCallback onSignout) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: context.read<CategoryBloc>()),
          BlocProvider.value(value: context.read<ShopBloc>()),
        ],
        child: SettingsSheet(onSignout: onSignout),
      ),
    );
  }

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
    AppLocalizations.of(context);
    final counts = context.watch<ShopBloc>().state.asLoaded?.pagination.total ?? 0;

    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              ShopHeader(
                onSettingsPressed: () => _showSettingsSheet(
                  () => context.read<SignoutBloc>().add(const SignoutSubmitted()),
                ),
                onSearchChanged: _onSearchChanged,
                onFilterPressed: _showFilterSheet,
                searchController: _searchController,
              ),
              ShopList(onRefresh: _refreshItems),
            ],
          ),
          ItemCount(counts: counts),
        ],
      ),
    );
  }
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

// Error View Widget
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
