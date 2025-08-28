import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';
import 'package:my_app/app/app.dart';
import 'package:my_app/home/home.dart';
import 'package:my_app/shop/shop.dart';
import 'package:shimmer/shimmer.dart';

class CategoryChips extends StatelessWidget {
  const CategoryChips({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ShopBloc, ShopState>(
      builder: (context, shopState) {
        final currentShopState = shopState.asLoaded;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              InkWell(
                onTap: () => context.read<ShopBloc>().add(ShopGetItemsEvent()),
                child: Chip(
                  label: const Text('All'),
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  backgroundColor: currentShopState?.categoryFilter == null
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.surface,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  labelStyle: TextStyle(
                    color: currentShopState?.categoryFilter == null
                        ? Theme.of(context).colorScheme.onPrimary
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: 2),
              SizedBox(
                height: 30,
                width: 8,
                child: VerticalDivider(
                  color: Colors.grey[200],
                ),
              ),
              BlocBuilder<CategoryBloc, CategoryState>(
                builder: (context, state) {
                  if (state is CategoryLoaded) {
                    return Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: List.generate(
                            state.items.length,
                            (index) {
                              final category = state.items[index];
                              final isSelected = currentShopState?.categoryFilter?.name == category.name;
                              return Padding(
                                padding: EdgeInsets.only(
                                  right: index == state.items.length - 1 ? 0 : 4,
                                ),
                                child: InkWell(
                                  onTap: () => context.read<ShopBloc>().add(
                                        ShopGetItemsEvent(categoryFilter: category),
                                      ),
                                  child: Chip(
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    visualDensity: VisualDensity.compact,
                                    padding: const EdgeInsets.symmetric(horizontal: 4),
                                    label: Text(category.name),
                                    backgroundColor: isSelected
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(context).colorScheme.surface,
                                    labelStyle: TextStyle(
                                      color: isSelected
                                          ? Theme.of(context).colorScheme.onPrimary
                                          : Theme.of(context).colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ).toList(),
                        ),
                      ),
                    );
                  }

                  if (state is CategoryLoading) {
                    return Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: List.generate(
                            5,
                            (index) => Padding(
                              padding: EdgeInsets.only(
                                right: index == 4 ? 0 : 4,
                              ),
                              child: Shimmer.fromColors(
                                baseColor: Colors.grey[300]!,
                                highlightColor: Colors.grey[100]!,
                                child: Chip(
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  visualDensity: VisualDensity.compact,
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  label: Container(
                                    width: 30,
                                    height: 20,
                                    color: Colors.white,
                                  ),
                                  backgroundColor: Theme.of(context).colorScheme.surface,
                                ),
                              ),
                            ),
                          ).toList(),
                        ),
                      ),
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

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
    return CustomScrollView(
      controller: controller,
      physics: const BouncingScrollPhysics().applyTo(const AlwaysScrollableScrollPhysics()),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16).copyWith(bottom: 52),
          sliver: SliverToBoxAdapter(
            child: MasonryGridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.items.length,
              itemBuilder: (context, index) => GridShopItemCard(
                key: ValueKey(widget.items[index].id),
                item: widget.items[index],
                onEdit: (item) => _showEditSheet(context, item),
              ),
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              padding: EdgeInsets.zero,
              gridDelegate: SliverSimpleGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
              ),
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
          child: SizedBox(height: 70),
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
}
