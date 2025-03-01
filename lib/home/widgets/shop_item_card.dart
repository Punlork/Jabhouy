import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

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
    super.key,
  });

  final ShopItem item;
  final void Function(ShopItem) onEdit;

  @override
  Widget build(BuildContext context) {
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
              onPressed: (_) {},
              borderRadius: BorderRadius.circular(12),
              foregroundColor: Colors.red,
              icon: Icons.delete,
            ),
          ],
        ),
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: EdgeInsets.zero,
          color: Colors.white,
          child: _ShopItemCardContent(item: item),
        ),
      ),
    );
  }
}

// Extracted content widget to prevent unnecessary rebuilds
class _ShopItemCardContent extends StatelessWidget {
  const _ShopItemCardContent({required this.item});

  final ShopItem item;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 16),
      leading: CachedNetworkImage(
        imageUrl: item.imageUrl,
        width: 60,
        height: 60,
        fit: BoxFit.cover,
        memCacheHeight: 120, // Cache smaller image
        memCacheWidth: 120,
        placeholder: (context, url) => Container(
          width: 60,
          height: 60,
          color: Colors.grey[300],
        ),
        errorWidget: (context, url, error) => const Icon(
          Icons.broken_image,
          size: 60,
        ),
      ),
      title: Text(
        item.name,
        style: textTheme.titleMedium?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(
            'Category: ${item.category}',
            style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 4),
          Text(
            '\$${item.sellerPrice.toStringAsFixed(2)} / unit',
            style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
        ],
      ),
      children: [
        // Padding(
        //   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        //   child: Column(
        //     crossAxisAlignment: CrossAxisAlignment.start,
        //     children: [
        //       Text(
        //         'Note:',
        //         style: textTheme.labelMedium?.copyWith(color: colorScheme.onSurfaceVariant),
        //       ),
        //       const SizedBox(height: 4),
        //       Text(
        //         item.note,
        //         style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
        //       ),
        //       const SizedBox(height: 8),
        //       Text(
        //         'Base: \$${item.defaultBatchPrice.toStringAsFixed(2)} / ${item.batchSize}-pack',
        //         style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
        //       ),
        //       const SizedBox(height: 16),
        //       Row(
        //         crossAxisAlignment: CrossAxisAlignment.start,
        //         children: [
        //           Expanded(
        //             child: Column(
        //               crossAxisAlignment: CrossAxisAlignment.start,
        //               children: [
        //                 Row(
        //                   children: [
        //                     Icon(Icons.person, size: 16, color: colorScheme.primary),
        //                     const SizedBox(width: 4),
        //                     Text(
        //                       'Customer',
        //                       style: textTheme.labelMedium?.copyWith(color: colorScheme.primary),
        //                     ),
        //                   ],
        //                 ),
        //                 const SizedBox(height: 4),
        //                 Text(
        //                   '\$${item.customerPrice.toStringAsFixed(2)} / unit',
        //                   style: textTheme.bodyLarge?.copyWith(
        //                     color: colorScheme.primary,
        //                     fontWeight: FontWeight.bold,
        //                   ),
        //                 ),
        //                 Text(
        //                   '\$${item.customerBatchPrice.toStringAsFixed(2)} / ${item.batchSize}-pack',
        //                   style: textTheme.bodyMedium?.copyWith(color: colorScheme.primary),
        //                 ),
        //               ],
        //             ),
        //           ),
        //           Expanded(
        //             child: Column(
        //               crossAxisAlignment: CrossAxisAlignment.start,
        //               children: [
        //                 Row(
        //                   children: [
        //                     Icon(Icons.store, size: 16, color: colorScheme.secondary),
        //                     const SizedBox(width: 4),
        //                     Text(
        //                       'Seller',
        //                       style: textTheme.labelMedium?.copyWith(color: colorScheme.secondary),
        //                     ),
        //                   ],
        //                 ),
        //                 const SizedBox(height: 4),
        //                 Text(
        //                   '\$${item.sellerPrice.toStringAsFixed(2)} / unit',
        //                   style: textTheme.bodyLarge?.copyWith(
        //                     color: colorScheme.secondary,
        //                     fontWeight: FontWeight.bold,
        //                   ),
        //                 ),
        //                 Text(
        //                   '\$${item.sellerBatchPrice.toStringAsFixed(2)} / ${item.batchSize}-pack',
        //                   style: textTheme.bodyMedium?.copyWith(color: colorScheme.secondary),
        //                 ),
        //               ],
        //             ),
        //           ),
        //         ],
        //       ),
        //     ],
        //   ),
        // ),
      ],
    );
  }
}
