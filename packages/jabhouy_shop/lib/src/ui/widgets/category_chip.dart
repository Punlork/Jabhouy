import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jabhouy_l10n/jabhouy_l10n.dart';
import 'package:jabhouy_shop/jabhouy_shop.dart';
import 'package:shimmer/shimmer.dart';

class CategoryChips extends StatelessWidget {
  const CategoryChips({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BlocBuilder<ShopBloc, ShopState>(
      builder: (context, shopState) {
        final currentShopState = shopState.asLoaded;

        final categoryState = context.watch<CategoryBloc>().state;
        final isAllSelected = currentShopState?.categoryFilter == null;

        final categoryChips = switch (categoryState) {
          CategoryLoaded(:final items) => [
              for (final category in items)
                InkWell(
                  borderRadius: BorderRadius.circular(19),
                  onTap: () {
                    if (currentShopState?.categoryFilter?.name ==
                        category.name) {
                      return;
                    }
                    context.read<ShopBloc>().add(
                          ShopGetItemsEvent(categoryFilter: category),
                        );
                  },
                  child: _buildChip(
                    context,
                    label: category.name,
                    isSelected: currentShopState?.categoryFilter?.name ==
                        category.name,
                  ),
                ),
            ],
          CategoryLoading() => [
              for (var i = 0; i < 5; i++)
                Shimmer.fromColors(
                  baseColor: colorScheme.surfaceContainerHighest,
                  highlightColor: colorScheme.surfaceContainerHigh,
                  child: Chip(
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    label: Container(
                      width: 30,
                      height: 20,
                      color: colorScheme.surfaceContainerHighest,
                    ),
                    backgroundColor: colorScheme.surface,
                  ),
                ),
            ],
          _ => const <Widget>[],
        };

        // Edge to edge, like a pinned tab bar: the grid scrolls under it,
        // and the chips scroll to the screen edges instead of stopping at
        // an inset box. Fits the 52 px the grid leaves at its top.
        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: colorScheme.surface,
            border: Border(
              bottom: BorderSide(color: colorScheme.outlineVariant),
            ),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(19),
                  onTap: () {
                    if (isAllSelected) return;
                    context.read<ShopBloc>().add(
                          ShopGetItemsEvent(clearCategoryFilter: true),
                        );
                  },
                  child: _buildChip(
                    context,
                    label: context.l10n.all,
                    isSelected: isAllSelected,
                  ),
                ),
                if (categoryChips.isNotEmpty)
                  SizedBox(
                    height: 24,
                    width: 17,
                    child: VerticalDivider(color: colorScheme.outlineVariant),
                  ),
                for (final (index, chip) in categoryChips.indexed)
                  Padding(
                    padding: EdgeInsets.only(left: index == 0 ? 0 : 6),
                    child: chip,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildChip(
    BuildContext context, {
    required String label,
    required bool isSelected,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Theme(
      data: ThemeData(canvasColor: Colors.transparent),
      child: Chip(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(19),
        ),
        // Filled and borderless, like the header's search field and
        // filter button: the same off and on colors as that button.
        side: BorderSide.none,
        labelPadding: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.symmetric(horizontal: 6),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
        label: Text(label),
        backgroundColor: isSelected
            ? colorScheme.primaryContainer
            : colorScheme.surfaceContainerHigh,
        labelStyle: TextStyle(
          color: isSelected
              ? colorScheme.onPrimaryContainer
              : colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
