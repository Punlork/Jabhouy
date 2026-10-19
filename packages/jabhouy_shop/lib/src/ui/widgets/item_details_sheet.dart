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
      (final at?, null) => l10n.lastEditedOn(l10n.formatDate(at.toPhnomPenh())),
      (final at?, final name?) => l10n.lastEditedBy(
        l10n.formatDate(at.toPhnomPenh()),
        name,
      ),
    };
    const buttonSize = Size.fromHeight(52);

    return AppBottomSheet(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: t.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _Header(item: item, categoryName: categoryName),
            const SizedBox(height: 8),
            if (item.prices.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: PriceDisplay(
                  price: null,
                  khrPerUsd: 0,
                  showConverted: false,
                ),
              ),
            for (final (i, option) in item.prices.indexed)
              _PriceBlock(
                option: option,
                settings: settings,
                divider: i < item.prices.length - 1,
              ),
            if (editedLine != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  editedLine,
                  style: AppTextTheme.hint.copyWith(color: t.textMuted),
                ),
              ),
            if (canEdit) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: onEdit,
                      style: FilledButton.styleFrom(minimumSize: buttonSize),
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: Text(l10n.priceEdit),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _confirmDelete(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: t.dangerText,
                        side: BorderSide(color: t.dangerBorder),
                        minimumSize: buttonSize,
                      ),
                      icon: const Icon(Icons.delete_outline_rounded, size: 18),
                      label: Text(l10n.delete),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Thumbnail, name and category tag, with the close button.
class _Header extends StatelessWidget {
  const _Header({required this.item, this.categoryName});

  final Item item;
  final String? categoryName;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final letter = item.name.isEmpty
        ? ''
        : String.fromCharCode(item.name.runes.first);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 64,
          height: 64,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: t.surfaceMuted,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            letter,
            style: AppTextTheme.pageTitle.copyWith(
              fontSize: 24,
              color: t.textMuted,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.name,
                style: AppTextTheme.pageTitle.copyWith(color: t.textPrimary),
              ),
              if (categoryName != null) ...[
                const SizedBox(height: 4),
                // No alignment: an aligned Container fills the width.
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: t.surfaceSubtle,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Text(
                    categoryName!,
                    style: AppTextTheme.hint.copyWith(color: t.textSecondary),
                  ),
                ),
              ],
            ],
          ),
        ),
        IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
          icon: Icon(Icons.close_rounded, color: t.textSecondary),
        ),
      ],
    );
  }
}

/// One Price option: `1 ដប` and the big price, the converted line, then
/// wholesale and cost in one muted line.
class _PriceBlock extends StatelessWidget {
  const _PriceBlock({
    required this.option,
    required this.settings,
    required this.divider,
  });

  final PriceOption option;
  final PriceSettings settings;
  final bool divider;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final t = context.tokens;
    final muted = AppTextTheme.hint.copyWith(color: t.textMuted);
    String line(String label, Money? money) =>
        '$label: ${money?.format() ?? '—'}';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: divider ? Border(bottom: BorderSide(color: t.divider)) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text.rich(
                  TextSpan(
                    text: '1 ${option.unit}',
                    children: [
                      if (option.packQty != null)
                        TextSpan(
                          text: ' · ×${option.packQty}',
                          style: TextStyle(
                            color: t.textMuted,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                    ],
                  ),
                  style: AppTextTheme.body.copyWith(
                    color: t.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              PriceDisplay(
                price: option.selling,
                khrPerUsd: settings.khrPerUsd,
                showConverted: true,
                style: AppTextTheme.price.copyWith(fontSize: 20),
              ),
            ],
          ),
          if (settings.useWholesale || settings.useCost) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 16,
              children: [
                if (settings.useWholesale)
                  Text(
                    line(l10n.priceWholesaleLabel, option.wholesaleMoney),
                    style: muted,
                  ),
                if (settings.useCost)
                  Text(
                    line(l10n.priceCostShort, option.costMoney),
                    style: muted,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
