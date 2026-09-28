import 'package:flutter/material.dart';
import 'package:jabhouy_core/jabhouy_core.dart';
import 'package:jabhouy_shop/jabhouy_shop.dart';
import 'package:jabhouy_shop/src/ui/widgets/shop_item_parts.dart';
import 'package:jabhouy_ui/jabhouy_ui.dart';
import 'package:shimmer/shimmer.dart';

class GridShopItemCard extends StatelessWidget {
  const GridShopItemCard({
    required this.item,
    required this.onEdit,
    super.key,
  });

  final ShopItemModel item;
  final void Function(ShopItemModel) onEdit;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final titleStyle = textTheme.titleSmall?.copyWith(
      color: colorScheme.onSurface,
      fontWeight: FontWeight.w600,
      height: 1.1,
    );

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      color: Theme.of(context).cardTheme.color,
      child: InkWell(
        onTap: () => onEdit(item),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // One height for photos and letter tiles alike, so the cards
            // in a row line up whether or not they have a photo.
            AspectRatio(
              aspectRatio: 4 / 3,
              child: Hero(
                tag: 'shop_item_grid_${item.id}',
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: ShopItemThumbnail(item: item),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          item.productName,
                          style: titleStyle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SyncStateIcon(
                        isPending: item.syncStatus == SyncStatus.pending,
                        isFailed: item.syncStatus == SyncStatus.failed,
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  ShopItemVariantLine(
                    item: item,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ShopItemPrice(
                    item: item,
                    style: textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (item.category?.name case final category?) ...[
                    const SizedBox(height: 6),
                    ShopItemCategoryChip(name: category),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GridShopItemShimmer extends StatelessWidget {
  const GridShopItemShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: ColoredBox(
        color: Theme.of(context).cardTheme.color ?? colorScheme.surfaceContainerLow,
        child: Shimmer.fromColors(
          baseColor: colorScheme.surfaceContainerHighest,
          highlightColor: colorScheme.surfaceContainerHigh,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AspectRatio(
                aspectRatio: 4 / 3,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const SizedBox(
                        width: double.infinity,
                        height: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const SizedBox(
                        width: 100,
                        height: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
