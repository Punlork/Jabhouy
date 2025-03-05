import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:my_app/app/app.dart';
import 'package:my_app/home/home.dart';

void showShopItemDetailSheet({
  required BuildContext context,
  required ShopItem item,
  required VoidCallback onEdit,
  required VoidCallback onDelete,
}) =>
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) => SingleChildScrollView(
        child: ShopItemDetailSheet(
          item: item,
          onEdit: onEdit,
          onDelete: onDelete,
        ),
      ),
    );

class ShopItem {
  ShopItem({
    required this.name,
    required this.customerPrice,
    required this.customerBatchPrice,
    required this.sellerPrice,
    required this.sellerBatchPrice,
    required this.batchSize,
    required this.imageUrl,
    required this.category,
    required this.defaultBatchPrice,
    this.note, // Optional, if rarely used
  });

  factory ShopItem.fromJson(Map<String, dynamic> json) {
    return ShopItem(
      name: json['name'] as String,
      customerPrice: (json['customer_price'] as num).toDouble(),
      defaultBatchPrice: (json['default_batch_price'] as num).toDouble(),
      customerBatchPrice: (json['customer_batch_price'] as num).toDouble(),
      sellerPrice: (json['seller_price'] as num).toDouble(),
      sellerBatchPrice: (json['seller_batch_price'] as num).toDouble(),
      batchSize: json['batch_size'] as int,
      imageUrl: json['image_url'] as String,
      category: json['category'] as String,
      note: json['note'] as String?,
    );
  }

  final String name;
  final double customerPrice;
  final double customerBatchPrice;
  final double sellerPrice;
  final double sellerBatchPrice;
  final double defaultBatchPrice;
  final int batchSize;
  final String imageUrl;
  final String category;
  final String? note; // Made optional
}

class ShopItemCard extends StatelessWidget {
  const ShopItemCard({
    required this.item,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  final ShopItem item;
  final void Function(ShopItem) onEdit;
  final void Function(ShopItem) onDelete;

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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
                  child: CachedNetworkImage(
                    imageUrl: item.imageUrl,
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                    memCacheHeight: 200,
                    memCacheWidth: 200,
                    placeholder: (context, url) => Container(
                      width: 100,
                      height: 100,
                      color: Colors.grey[300],
                    ),
                    errorWidget: (context, url, error) => const AppLogo(
                      shape: BoxShape.rectangle,
                      size: 100,
                      useBg: false,
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
                          '\$${item.customerPrice.toStringAsFixed(2)} / unit',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Batch Price
                        Text(
                          '\$${item.customerBatchPrice.toStringAsFixed(2)} / ${item.batchSize}-pack',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
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
