import 'package:flutter/material.dart';
import 'package:my_app/app/app.dart';
import 'package:my_app/l10n/l10n.dart';
import 'package:my_app/shop/shop.dart';

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
      builder: (context) => SingleChildScrollView(
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
    final l10n = AppLocalizations.of(context); // Access translations

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with image and name
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  item.imageUrl ?? '',
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const AppLogo(
                    shape: BoxShape.rectangle,
                    useBg: false,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.category ?? l10n.na,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey.shade600,
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
            l10n.defaultPrice,
            item.defaultPrice != null ? '${item.defaultPrice!.toInt()} រៀល' : l10n.na,
            context,
          ),
          _buildDetailRow(
            l10n.customerPrice,
            item.customerPrice != null ? '${item.customerPrice!.toInt()} រៀល' : l10n.na,
            context,
          ),

          _buildDetailRow(
            l10n.sellerPrice,
            item.sellerPrice != null ? '${item.sellerPrice!.toInt()} រៀល' : l10n.na,
            context,
          ),

          // Note (if available)
          if (item.note != null && item.note!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              l10n.note,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              item.note!,
              style: Theme.of(context).textTheme.bodyMedium,
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
                  icon: const Icon(
                    Icons.edit,
                    color: Colors.white,
                  ),
                  label: Text(l10n.edit),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _confirmDelete(context),
                  icon: const Icon(Icons.delete),
                  label: Text(l10n.delete),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                    side: BorderSide(color: Theme.of(context).colorScheme.error),
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
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade700,
                  ),
            ),
            Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
        title: Text(l10n.confirmDelete),
        content: Text(l10n.confirmDeleteMessage(item.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.cancel),
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
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }
}
