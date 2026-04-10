import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';
import 'package:my_app/app/app.dart';
import 'package:my_app/home/home.dart';
import 'package:my_app/shop/shop.dart';

class ShopGridBuilder extends StatefulWidget {
  const ShopGridBuilder({
    required this.items,
    required this.pagination,
    super.key,
  });

  final List<ShopItemModel> items;
  final Pagination pagination;

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
    final crossAxisCount = _resolveCrossAxisCount(
      context,
      itemCount: widget.items.length,
    );

    return CustomScrollView(
      controller: controller,
      physics: const BouncingScrollPhysics().applyTo(
        const AlwaysScrollableScrollPhysics(),
      ),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
          ).copyWith(
            bottom: 52,
            top: 52,
          ),
          sliver: SliverAlignedGrid.count(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            itemCount: widget.items.length,
            itemBuilder: (context, index) => GridShopItemCard(
              key: ValueKey(widget.items[index].id),
              item: widget.items[index],
              onEdit: (item) => _showEditSheet(context, item),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Builder(
            builder: (context) {
              Widget child = const SizedBox.shrink();
              if (widget.pagination.hasNext) {
                child = const CustomLoading();
              }
              return child;
            },
          ),
        ),
        const SliverToBoxAdapter(
          child: SizedBox(height: 20),
        ),
      ],
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

  int _resolveCrossAxisCount(
    BuildContext context, {
    required int itemCount,
  }) {
    final preferredCount = MediaQuery.sizeOf(context).width > 600 ? 3 : 2;

    if (itemCount <= 0) {
      return preferredCount;
    }

    return preferredCount;
  }
}
