import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:my_app/app/app.dart';
import 'package:my_app/l10n/l10n.dart';
import 'package:my_app/shop/shop.dart';

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
    final l10n = context.l10n;

    return GestureDetector(
      onTap: () => onEdit(item), // Tap to edit
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image
            Expanded(
              flex: 2,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: ColoredBox(
                  color: Colors.white,
                  child: CachedNetworkImage(
                    imageUrl: item.imageUrl ?? '',
                    fit: BoxFit.cover,
                    memCacheHeight: 200,
                    memCacheWidth: 200,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[300],
                    ),
                    errorWidget: (context, url, error) => const AppLogo(
                      shape: BoxShape.rectangle,
                      useBg: false,
                      size: 50,
                    ),
                  ),
                ),
              ),
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Title
                    Text(
                      item.name,
                      style: textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    // Price per unit
                    Text(
                      '\$${item.customerPrice?.toStringAsFixed(2)}${l10n.perUnit}',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    // Batch Price
                    Text(
                      '\$${item.customerBatchPrice?.toStringAsFixed(2)}${l10n.perBatchPack(item.batchSize?.toString() ?? l10n.na)}',
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
    );
  }
}
