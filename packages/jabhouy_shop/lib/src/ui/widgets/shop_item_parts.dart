import 'package:flutter/material.dart';
import 'package:jabhouy_l10n/jabhouy_l10n.dart';
import 'package:jabhouy_shop/jabhouy_shop.dart';
import 'package:transparent_image/transparent_image.dart';

/// `40,000 ៛`, or `—` when there is no price.
///
/// Riel amounts run to five and six digits, so they are grouped; `៛` is
/// the riel sign, shorter than the word on a narrow card.
String formatRiel(int? amount) {
  if (amount == null) return '—';
  final digits = amount.abs().toString();
  final grouped = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) grouped.write(',');
    grouped.write(digits[i]);
  }
  return '${amount < 0 ? '-' : ''}$grouped ៛';
}

/// The item's photo, or a tile with its first letter.
///
/// Most items have no photo, and a full-size logo repeated on every card
/// was most of what the listing showed.
class ShopItemThumbnail extends StatelessWidget {
  const ShopItemThumbnail({required this.item, super.key});

  final ShopItemModel item;

  @override
  Widget build(BuildContext context) {
    final url = item.imageUrl;
    if (url == null || url.isEmpty) return _LetterTile(name: item.productName);
    return FadeInImage.memoryNetwork(
      image: url,
      fit: BoxFit.cover,
      imageCacheHeight: 250,
      imageCacheWidth: 250,
      placeholder: kTransparentImage,
      imageErrorBuilder: (context, url, error) =>
          _LetterTile(name: item.productName),
    );
  }
}

class _LetterTile extends StatelessWidget {
  const _LetterTile({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    // One neutral for every tile. A tint per name came out as light grey
    // or near-black in this theme's near-monochrome containers, which drew
    // the eye to tiles that meant nothing.
    final colorScheme = Theme.of(context).colorScheme;
    final letter = name.isEmpty ? '?' : name.characters.first.toUpperCase();

    return ColoredBox(
      color: colorScheme.surfaceContainerHighest,
      child: Center(
        child: Text(
          letter,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
        ),
      ),
    );
  }
}

/// `Pack Can · ×24`: the variant label, then the pack size.
///
/// The label is what tells two variants of one product apart, so it gets
/// its own line instead of being clipped off the end of the name. It is
/// also what shrinks when space runs out; the pack size always shows.
class ShopItemVariantLine extends StatelessWidget {
  const ShopItemVariantLine({required this.item, this.style, super.key});

  final ShopItemModel item;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final label = item.variantLabel.isNotEmpty
        ? item.variantLabel
        : (item.isPack ? l10n.packItem : l10n.singleItem);
    final pack = item.packAmount;

    return Row(
      children: [
        Flexible(
          child: Text(
            label,
            style: style,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (item.isPack && pack != null) Text(' · ×$pack', style: style),
      ],
    );
  }
}

/// The category, clipped with `…` rather than widening the card.
class ShopItemCategoryChip extends StatelessWidget {
  const ShopItemCategoryChip({required this.name, super.key});

  final String name;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Flexible(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// The one price the listing shows: what the seller quotes a customer.
/// Scales down rather than overflowing on a very long number.
class ShopItemPrice extends StatelessWidget {
  const ShopItemPrice({required this.item, this.style, super.key});

  final ShopItemModel item;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Text(formatRiel(item.customerPrice), style: style, maxLines: 1),
    );
  }
}
