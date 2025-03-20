import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:my_app/app/app.dart';
import 'package:my_app/home/home.dart';
import 'package:my_app/shop/shop.dart';

class ShopGridBuilder extends StatefulWidget {
  const ShopGridBuilder({super.key});

  @override
  State<ShopGridBuilder> createState() => _ShopGridBuilderState();
}

class _ShopGridBuilderState extends State<ShopGridBuilder>
    with AutomaticKeepAliveClientMixin, InfiniteScrollMixin<ShopGridBuilder> {
  @override
  ScrollController? getScrollController(BuildContext context) => TabScrollManager.of(context)?.getController(0);

  @override
  void onScrollToBottom() {
    if (!mounted) return;
    final state = context.read<ShopBloc>().state.asLoaded;
    if (state != null && state.pagination.hasNext) {
      context.read<ShopBloc>().add(
            ShopGetItemsEvent(
              page: state.pagination.page + 1,
              limit: state.pagination.limit,
              searchQuery: state.searchQuery,
              categoryFilter: state.categoryFilter,
            ),
          );
    }
  }

  @override
  void initState() {
    super.initState();
    setupScrollListener(context);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BlocBuilder<ShopBloc, ShopState>(
      builder: (context, state) => switch (state) {
        ShopLoaded(:final items, :final pagination) => CustomScrollView(
            controller: controller,
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
        _ => const SizedBox.shrink(),
      },
    );
  }

  void _showEditSheet(BuildContext context, ShopItemModel item) {
    if (!mounted) return;
    showShopItemDetailSheet(
      context: context,
      item: item,
      onEdit: () {
        if (!mounted) return;
        context
          ..pop()
          ..pushNamed(
            AppRoutes.formShop,
            extra: {
              'existingItem': item,
              'shop': context.read<ShopBloc>(),
              'category': context.read<CategoryBloc>(),
            },
          );
      },
      onDelete: () {
        if (!mounted) return;
        context.read<ShopBloc>().add(
              ShopDeleteItemEvent(body: item),
            );
      },
    );
  }

  @override
  void dispose() {
    disposeScrollListener();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;
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
