import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:my_app/app/app.dart';
import 'package:my_app/shop/shop.dart';

class ShopGridBuilder extends StatefulWidget {
  const ShopGridBuilder({super.key});

  @override
  State<ShopGridBuilder> createState() => _ShopGridBuilderState();
}

class _ShopGridBuilderState extends State<ShopGridBuilder> {
  late final ScrollController _scrollController;

  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  bool get _isScrollAtBottom {
    if (!_scrollController.hasClients) return false;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }

  void _onScroll() {
    if (_isScrollAtBottom) {
      final state = context.read<ShopBloc>().state.asLoaded;
      if (state != null && state.pagination.hasNext) {
        context.read<ShopBloc>().add(
              ShopGetItemsEvent(
                page: state.pagination.page + 1,
                pageSize: state.pagination.pageSize,
                searchQuery: state.searchQuery,
                categoryFilter: state.categoryFilter,
                buyerFilter: state.buyerFilter,
              ),
            );
      }
    }
  }

  void _showEditSheet(BuildContext context, ShopItemModel item) {
    showShopItemDetailSheet(
      context: context,
      item: item,
      onEdit: () {
        context
          ..pop()
          ..pushNamed(
            AppRoutes.createShopItem,
            extra: {
              'existingItem': item,
              'shop': context.read<ShopBloc>(),
              'category': context.read<CategoryBloc>(),
            },
          );
      },
      onDelete: () => context.read<ShopBloc>().add(
            ShopDeleteItemEvent(body: item),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ShopBloc, ShopState>(
      buildWhen: (previous, current) {
        if (previous is ShopLoaded && current is ShopLoaded) {
          for (var i = 0; i < previous.asLoaded!.items.length; i++) {
            if (previous.items[i] != current.items[i]) {
              return true;
            }
          }

          return previous.searchQuery != current.searchQuery ||
              previous.categoryFilter != current.categoryFilter ||
              previous.buyerFilter != current.buyerFilter ||
              previous.items.length != current.items.length;
        }

        return true;
      },
      builder: (context, state) => switch (state) {
        ShopLoading() => const Center(child: CustomLoading()),
        ShopLoaded(:final items, :final pagination) => CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics().applyTo(const AlwaysScrollableScrollPhysics()),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverGrid.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) => GridShopItemCard(
                    key: ValueKey(items[index].id),
                    item: items[index],
                    onEdit: (item) => _showEditSheet(context, item),
                  ),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.8,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Builder(
                  builder: (context) {
                    Widget child = const SizedBox.shrink();

                    if (pagination.hasNext) {
                      child = const CustomLoading();
                    } else {
                      child = const _EndOfListIndicator();
                    }

                    return child;
                  },
                ),
              ),
            ],
          ),
        ShopError(:final message) => Center(child: Text(message)),
        _ => const SizedBox.shrink(),
      },
    );
  }
}

class _EndOfListIndicator extends StatelessWidget {
  const _EndOfListIndicator();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      child: const Center(
        child: Text(
          'No more items',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }
}
