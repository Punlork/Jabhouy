import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:my_app/shop/shop.dart';
import 'package:transparent_image/transparent_image.dart';

class ShopItemCard extends StatelessWidget {
  const ShopItemCard({
    required this.item,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  final ShopItemModel item;
  final void Function(ShopItemModel) onEdit;
  final void Function(ShopItemModel) onDelete;

  void _confirmDelete(BuildContext context) => showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Confirm Delete'),
          content: Text('Are you sure you want to delete "${item.name}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                onDelete(item);
              },
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text('Delete'),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Slidable(
        endActionPane: ActionPane(
          motion: const ScrollMotion(),
          children: [
            const SizedBox(width: 8),
            SlidableAction(
              onPressed: (_) => onEdit(item),
              borderRadius: BorderRadius.circular(12),
              icon: Icons.edit,
            ),
            const SizedBox(width: 8),
            SlidableAction(
              onPressed: (_) => _confirmDelete(context),
              borderRadius: BorderRadius.circular(12),
              icon: Icons.delete,
              foregroundColor: Colors.white,
            ),
          ],
        ),
        child: Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          color: Theme.of(context).cardTheme.color,
          surfaceTintColor: colorScheme.surfaceTint,
          child: InkWell(
            onTap: () => showShopItemDetailSheet(
              context: context,
              item: item,
              onEdit: () => onEdit(item),
              onDelete: () => onDelete(item),
            ),
            child: Row(
              children: [
                Hero(
                  tag: 'shop_item_${item.id}',
                  child: ClipRRect(
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(16),
                    ),
                    child: FadeInImage.memoryNetwork(
                      image: item.imageUrl ?? '',
                      fadeInDuration: const Duration(milliseconds: 200),
                      fit: BoxFit.cover,
                      height: 110,
                      width: 110,
                      placeholder: kTransparentImage,
                      imageErrorBuilder: (context, url, error) => Container(
                        height: 110,
                        width: 110,
                        color: colorScheme.surfaceContainerHighest,
                        child: Icon(
                          Icons.inventory_2_outlined,
                          color: colorScheme.onSurfaceVariant
                              .withValues(alpha: 0.5),
                          size: 32,
                        ),
                      ),
                    ),
                  ),
                ),
                // Content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name
                        Text(
                          item.name,
                          style: textTheme.titleMedium?.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        // Price
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '\$${item.customerPrice?.toStringAsFixed(2)} / unit',
                            style: textTheme.labelLarge?.copyWith(
                              color: colorScheme.onSecondaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
