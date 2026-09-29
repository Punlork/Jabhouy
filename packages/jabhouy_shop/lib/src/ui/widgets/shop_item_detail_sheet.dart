import 'package:flutter/material.dart';
import 'package:jabhouy_l10n/jabhouy_l10n.dart';
import 'package:jabhouy_shop/jabhouy_shop.dart';
import 'package:jabhouy_shop/src/ui/widgets/shop_item_parts.dart';
import 'package:jabhouy_ui/jabhouy_ui.dart';

void showShopItemDetailSheet({
  required BuildContext context,
  required ShopItemModel item,
  required VoidCallback onEdit,
  required VoidCallback onDelete,
}) =>
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) => AppBottomSheet(
        child: ShopItemDetailSheet(
          item: item,
          onEdit: onEdit,
          onDelete: onDelete,
        ),
      ),
    );

class ShopItemDetailSheet extends StatelessWidget {
  const ShopItemDetailSheet({
    required this.item,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  final ShopItemModel item;
  final VoidCallback onEdit;
  final dynamic Function() onDelete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context); // Access translations

    // No decoration: the modal sheet is the surface. A shadow here, with
    // nothing filling the box, painted a grey wash over the whole sheet.
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                // Same photo-or-letter tile as the listing card.
                child: SizedBox.square(
                  dimension: 80,
                  child: ShopItemThumbnail(item: item),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.displayName,
                      style: AppTextTheme.headline.copyWith(
                        fontWeight: FontWeight
                            .bold, // Already w700, but explicit for clarity
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.category?.name ?? l10n.na,
                      style: AppTextTheme.body.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Price Details
          _buildDetailRow(
            l10n.itemType,
            item.isPack ? l10n.packItem : l10n.singleItem,
            context,
          ),
          if (item.packAmount case final packAmount?)
            _buildDetailRow(
              l10n.packSize,
              '$packAmount ${l10n.itemsSuffix}',
              context,
            ),
          _buildDetailRow(
            l10n.defaultPrice,
            item.defaultPrice != null ? formatRiel(item.defaultPrice) : l10n.na,
            context,
          ),
          _buildDetailRow(
            l10n.customerPrice,
            item.customerPrice != null ? formatRiel(item.customerPrice) : l10n.na,
            context,
          ),
          _buildDetailRow(
            l10n.sellerPrice,
            item.sellerPrice != null ? formatRiel(item.sellerPrice) : l10n.na,
            context,
          ),

          // Note (if available)
          if (item.note != null && item.note!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              l10n.note,
              style: AppTextTheme.title.copyWith(
                fontWeight: FontWeight.bold, // Override w600 to w700
              ),
            ),
            const SizedBox(height: 4),
            Text(
              item.note!,
              style: AppTextTheme.body,
            ),
          ],

          const SizedBox(height: 24),

          // Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit),
                  label: Text(
                    l10n.edit,
                    style: AppTextTheme.body,
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _confirmDelete(context),
                  icon: const Icon(Icons.delete),
                  label: Text(
                    l10n.delete,
                    style: AppTextTheme.body,
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colorScheme.error,
                    side: BorderSide(color: colorScheme.error),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value,
    BuildContext context,
  ) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: AppTextTheme.body.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              value,
              style: AppTextTheme.body.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );

  void _confirmDelete(BuildContext context) {
    final l10n = AppLocalizations.of(context); // Access translations
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          l10n.confirmDelete,
          style: AppTextTheme.title,
        ),
        content: Text(
          l10n.confirmDeleteMessage(item.name),
          style: AppTextTheme.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              l10n.cancel,
              style: AppTextTheme.caption,
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await onDelete();
              if (context.mounted) Navigator.pop(context);
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(
              l10n.delete,
              style: AppTextTheme.caption,
            ),
          ),
        ],
      ),
    );
  }
}
