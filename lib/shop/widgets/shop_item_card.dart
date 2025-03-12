import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:my_app/app/app.dart';
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
              style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
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
        child: GestureDetector(
          onTap: () => showShopItemDetailSheet(
            context: context,
            item: item,
            onEdit: () => onEdit(item),
            onDelete: () => onDelete(item),
          ),
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: EdgeInsets.zero,
            color: Colors.white,
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
                  child: FadeInImage.memoryNetwork(
                    image: item.imageUrl ?? '',
                    fadeInDuration: const Duration(milliseconds: 15),
                    fit: BoxFit.cover,
                    height: 100,
                    width: 100,
                    placeholder: kTransparentImage,
                    imageErrorBuilder: (context, url, error) => const AppLogo(
                      shape: BoxShape.rectangle,
                      useBg: false,
                      size: 100,
                    ),
                  ),
                ),
                // Content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        // Name
                        Text(
                          item.name,
                          style: textTheme.titleMedium?.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 10),
                        // Price
                        Text(
                          '\$${item.customerPrice?.toStringAsFixed(2)} / unit',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
