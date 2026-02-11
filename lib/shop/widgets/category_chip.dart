import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
          ),
          child: Row(
            children: [
              InkWell(
                onTap: () => context.read<ShopBloc>().add(ShopGetItemsEvent()),
                child: _buildChip(
                  context,
                  label: 'All',
                  isSelected: currentShopState?.categoryFilter == null,
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
              const SizedBox(width: 2),
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
                                  child: _buildChip(
                                    context,
                                    label: category.name,
                                    isSelected: isSelected,
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

  Widget _buildChip(BuildContext context, {required String label, required bool isSelected}) {
    return Theme(
      data: ThemeData(canvasColor: Colors.transparent),
      child: Chip(
        side: const BorderSide(
          width: 0,
          color: Colors.transparent,
        ),
        labelPadding: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
        label: Text(label),
        backgroundColor: isSelected ? Theme.of(context).colorScheme.onPrimaryContainer : Colors.transparent,
        labelStyle: TextStyle(
          color: Theme.of(context).colorScheme.onPrimary,
        ),
      ),
    );
  }
}
