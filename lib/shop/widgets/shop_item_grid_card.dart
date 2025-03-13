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
                borderRadius: const BorderRadius.all(
                  Radius.circular(12),
                ),
                child: ColoredBox(
                  color: item.imageUrl?.isEmpty ?? true ? AppColorTheme.logoBG : Colors.transparent,
                  child: FadeInImage.memoryNetwork(
                    image: item.imageUrl ?? '',
                    fit: BoxFit.contain,
                    width: 40,
                    height: 40,
                    imageCacheHeight: 150,
                    imageCacheWidth: 150,
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
                      style: AppTextTheme.title.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.bold, // Override w600 to bold (w700)
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    // Price
                    Text(
                      '${item.customerPrice} រៀល',
                      style: AppTextTheme.caption.copyWith(
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
