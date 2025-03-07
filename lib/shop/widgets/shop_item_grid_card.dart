import 'package:flutter/material.dart';
import 'package:my_app/app/app.dart';
import 'package:my_app/shop/shop.dart';
import 'package:transparent_image/transparent_image.dart';

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

    return GestureDetector(
      onTap: () => onEdit(item), // Tap to edit
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 2,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: ColoredBox(
                  color: Colors.white,
                  child: FadeInImage.memoryNetwork(
                    image: item.imageUrl ?? '',
                    fadeInDuration: const Duration(milliseconds: 15),
                    fit: BoxFit.cover,
                    width: 40,
                    height: 40,
                    placeholder: kTransparentImage,
                    imageErrorBuilder: (context, url, error) => const AppLogo(
                      shape: BoxShape.rectangle,
                      useBg: false,
                      size: 40,
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
                    Text(
                      '${item.customerPrice?.toInt()} រៀល',
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
