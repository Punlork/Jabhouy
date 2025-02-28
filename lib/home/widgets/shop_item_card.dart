import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:shimmer/shimmer.dart';

class ShopItem {
  ShopItem({
    required this.name,
    required this.defaultPrice,
    required this.defaultBatchPrice,
    required this.customerPrice,
    required this.sellerPrice,
    required this.customerBatchPrice,
    required this.sellerBatchPrice,
    required this.batchSize,
    required this.note,
    required this.imageUrl,
    required this.category,
  });
  final String name;
  final double defaultPrice;
  final double defaultBatchPrice;
  final double customerPrice;
  final double sellerPrice;
  final double customerBatchPrice;
  final double sellerBatchPrice;
  final int batchSize;
  final String note;
  final String imageUrl;
  final String category;
}

class ShopItemCard extends StatelessWidget {
  const ShopItemCard({required this.item, super.key});
  final ShopItem item;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.all(8),
      child: Slidable(
        endActionPane: ActionPane(
          motion: const ScrollMotion(),
          children: [
            const SizedBox(width: 8),
            SlidableAction(
              onPressed: (context) {},
              borderRadius: BorderRadius.circular(12),
              icon: Icons.edit,
            ),
            const SizedBox(width: 8),
            Theme(
              data: Theme.of(context).copyWith(
                outlinedButtonTheme: const OutlinedButtonThemeData(
                  style: ButtonStyle(
                    iconColor: WidgetStatePropertyAll(Colors.red),
                  ),
                ),
              ),
              child: SlidableAction(
                onPressed: (context) {},
                borderRadius: BorderRadius.circular(12),
                foregroundColor: Colors.red,
                icon: Icons.delete,
              ),
            ),
          ],
        ),
        key: ValueKey(item.name),
        child: Card(
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: EdgeInsets.zero,
          color: Colors.white,
          child: ExpansionTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: item.imageUrl,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                placeholder: (context, url) => Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(
                    width: 60,
                    height: 60,
                    color: Colors.white,
                  ),
                ),
                errorWidget: (context, url, error) => const Icon(
                  Icons.broken_image,
                  size: 60,
                ),
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
                  style: textTheme.bodySmall
                      ?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'Base: ',
                      style: textTheme.bodySmall
                          ?.copyWith(color: colorScheme.onSurfaceVariant),
                    ),
                    Text(
                      '\$${item.defaultPrice.toStringAsFixed(2)} / unit',
                      style: textTheme.bodySmall
                          ?.copyWith(color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ],
            ),
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Note
                    Text(
                      'Note:',
                      style: textTheme.labelMedium
                          ?.copyWith(color: colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.note,
                      style: textTheme.bodyMedium
                          ?.copyWith(color: colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 8),
                    // Base Batch Price
                    Text(
                      'Base: \$${item.defaultBatchPrice.toStringAsFixed(2)} / ${item.batchSize}-pack',
                      style: textTheme.bodyMedium
                          ?.copyWith(color: colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 16),
                    // Customer and Seller Pricing
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Customer Pricing
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.person,
                                      size: 16, color: colorScheme.primary),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Customer',
                                    style: textTheme.labelMedium
                                        ?.copyWith(color: colorScheme.primary),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '\$${item.customerPrice.toStringAsFixed(2)} / unit',
                                style: textTheme.bodyLarge?.copyWith(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '\$${item.customerBatchPrice.toStringAsFixed(2)} / ${item.batchSize}-pack',
                                style: textTheme.bodyMedium
                                    ?.copyWith(color: colorScheme.primary),
                              ),
                            ],
                          ),
                        ),
                        // Seller Pricing
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.store,
                                      size: 16, color: colorScheme.secondary),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Seller',
                                    style: textTheme.labelMedium?.copyWith(
                                        color: colorScheme.secondary),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '\$${item.sellerPrice.toStringAsFixed(2)} / unit',
                                style: textTheme.bodyLarge?.copyWith(
                                  color: colorScheme.secondary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '\$${item.sellerBatchPrice.toStringAsFixed(2)} / ${item.batchSize}-pack',
                                style: textTheme.bodyMedium
                                    ?.copyWith(color: colorScheme.secondary),
                              ),
                            ],
                          ),
                        ),
                      ],
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
