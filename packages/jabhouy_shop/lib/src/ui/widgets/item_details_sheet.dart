import 'package:flutter/material.dart';
import 'package:jabhouy_core/jabhouy_core.dart';
import 'package:jabhouy_l10n/jabhouy_l10n.dart';
import 'package:jabhouy_shop/src/models/item.dart';
import 'package:jabhouy_ui/jabhouy_ui.dart';

/// An Item's prices at a glance (canvas ២). Every Member sees cost
/// (decision 2); only owner and editor get edit and delete.
class ItemDetailsSheet extends StatelessWidget {
  const ItemDetailsSheet({
    required this.item,
    required this.settings,
    required this.canEdit,
    required this.onEdit,
    required this.onDelete,
    this.categoryName,
    this.editorName,
    super.key,
  });

  final Item item;
  final PriceSettings settings;
  final bool canEdit;
  final VoidCallback onEdit;

  /// Called once the user has confirmed.
  final VoidCallback onDelete;
  final String? categoryName;

  /// The Member who saved last; null shows the date alone.
  final String? editorName;

  Future<void> _confirmDelete(BuildContext context) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.confirmDelete),
        content: Text(l10n.confirmDeleteMessage(item.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              l10n.delete,
              style: TextStyle(color: context.tokens.dangerText),
            ),
          ),
        ],
      ),
    );
    if (confirmed ?? false) onDelete();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final t = context.tokens;
    final edited = item.updatedAt;
    final editedLine = switch ((edited, editorName)) {
      (null, _) => null,
      (final at?, null) => l10n.lastEditedOn(
        l10n.formatDate(at.toPhnomPenh()),
      ),
      (final at?, final name?) => l10n.lastEditedBy(
        l10n.formatDate(at.toPhnomPenh()),
        name,
      ),
    };

    return AppSheet(
      title: item.name,
      footer: canEdit
          ? Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _confirmDelete(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: t.dangerText,
                      side: BorderSide(color: t.dangerBorder),
                      minimumSize: const Size.fromHeight(AppSizes.buttonHeight),
                    ),
                    child: Text(l10n.delete),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: onEdit,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(AppSizes.buttonHeight),
                    ),
                    child: Text(l10n.priceEdit),
                  ),
                ),
              ],
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (categoryName != null)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: t.surfaceSubtle,
                  borderRadius: BorderRadius.circular(AppSizes.radiusChip),
                ),
                child: Text(
                  categoryName!,
                  style: AppTextTheme.hint.copyWith(color: t.textSecondary),
                ),
              ),
            ),
          for (final option in item.prices)
            _PriceBlock(option: option, settings: settings),
          if (editedLine != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                editedLine,
                style: AppTextTheme.hint.copyWith(color: t.textMuted),
              ),
            ),
        ],
      ),
    );
  }
}

class _PriceBlock extends StatelessWidget {
  const _PriceBlock({required this.option, required this.settings});

  final PriceOption option;
  final PriceSettings settings;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final t = context.tokens;
    final pack = option.packQty == null ? '' : ' · ×${option.packQty}';
    final muted = AppTextTheme.hint.copyWith(color: t.textMuted);

    Widget secondary(String label, Money? money) => Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: muted)),
          Text(
            money?.format() ?? '—',
            style: AppTextTheme.label.copyWith(color: t.textSecondary),
          ),
        ],
      ),
    );

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: t.surface,
        border: Border.all(color: t.divider),
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  '1 ${option.unit}$pack',
                  style: AppTextTheme.label.copyWith(color: t.textSecondary),
                ),
              ),
              PriceDisplay(
                price: option.selling,
                khrPerUsd: settings.khrPerUsd,
                showConverted: true,
                style: AppTextTheme.amount,
              ),
            ],
          ),
          if (settings.useWholesale)
            secondary(l10n.priceWholesale, option.wholesaleMoney),
          if (settings.useCost) secondary(l10n.priceCost, option.costMoney),
        ],
      ),
    );
  }
}
