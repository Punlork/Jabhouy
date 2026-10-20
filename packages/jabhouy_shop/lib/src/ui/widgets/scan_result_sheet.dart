import 'package:flutter/material.dart';
import 'package:jabhouy_l10n/jabhouy_l10n.dart';
import 'package:jabhouy_shop/src/models/item.dart';
import 'package:jabhouy_ui/jabhouy_ui.dart';

/// What a scan found (canvas ១ឃ). Returns the [Item] to open, the [code]
/// to add a new Item with, or null to scan again.
Future<Object?> showScanResult(
  BuildContext context, {
  required String code,
  required List<Item> items,
}) => showAppSheet<Object>(
  context,
  initialSize: items.length == 1 ? 0.55 : 0.45,
  builder: (_, controller) =>
      _ScanResultSheet(code: code, items: items, scrollController: controller),
);

class _ScanResultSheet extends StatelessWidget {
  const _ScanResultSheet({
    required this.code,
    required this.items,
    this.scrollController,
  });

  final String code;
  final List<Item> items;
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final t = context.tokens;
    const buttonSize = Size.fromHeight(52);
    final found = items.isNotEmpty;
    final scanNext = FilledButton.icon(
      onPressed: () => Navigator.pop(context),
      style: FilledButton.styleFrom(minimumSize: buttonSize),
      icon: const Icon(Icons.qr_code_scanner_rounded, size: 20),
      label: Text(l10n.scanNext),
    );
    // Opens the one match, or adds an Item when nothing matched.
    final other = switch (items) {
      [final item] => (l10n.scanDetails, item as Object),
      [] => (l10n.itemAdd, code),
      _ => null,
    };

    return AppSheet(
      scrollController: scrollController,
      header: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: found ? t.successText : t.warningText,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              found ? l10n.scanFound(code) : l10n.scanNotFound(code),
              style: AppTextTheme.hint.copyWith(
                color: found ? t.successText : t.warningText,
              ),
            ),
          ),
        ],
      ),
      footer: Row(
        children: [
          if (other case (final label, final result)) ...[
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context, result),
                style: OutlinedButton.styleFrom(minimumSize: buttonSize),
                child: Text(label),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(child: scanNext),
        ],
      ),
      child: switch (items) {
        [] => const SizedBox(height: 8),
        [final item] => _Match(item: item, code: code),
        _ => Column(
          children: [
            for (final item in items)
              _Choice(
                item: item,
                code: code,
                onTap: () => Navigator.pop(context, item),
              ),
          ],
        ),
      },
    );
  }
}

/// The Item, its scanned row in a dark band with a big price, then the
/// other rows smaller.
class _Match extends StatelessWidget {
  const _Match({required this.item, required this.code});

  final Item item;
  final String code;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final t = context.tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            _Thumb(name: item.name),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                item.name,
                style: AppTextTheme.pageTitle.copyWith(color: t.textPrimary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        for (final option in item.prices)
          if (option.barcode == code)
            Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: t.textPrimary,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          option.label,
                          style: AppTextTheme.body.copyWith(
                            color: t.onPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          l10n.scanThisBarcode,
                          style: AppTextTheme.hint.copyWith(
                            color: t.onPrimary.withValues(alpha: 0.75),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    option.selling?.format() ?? l10n.priceMissing,
                    style: AppTextTheme.amount.copyWith(
                      color: t.onPrimary,
                      fontSize: option.selling == null ? 16 : 28,
                    ),
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Expanded(
                    child: Text(
                      option.label,
                      style: AppTextTheme.body.copyWith(color: t.textMuted),
                    ),
                  ),
                  Text(
                    option.selling?.format() ?? l10n.priceMissing,
                    style: AppTextTheme.price.copyWith(
                      color: option.selling == null
                          ? t.warningText
                          : t.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
        const SizedBox(height: 8),
      ],
    );
  }
}

/// One of several Items sharing the code (decision 41): name, and the
/// scanned row's label and price.
class _Choice extends StatelessWidget {
  const _Choice({required this.item, required this.code, required this.onTap});

  final Item item;
  final String code;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final option = item.prices.firstWhere((p) => p.barcode == code);
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: t.divider)),
        ),
        child: Row(
          children: [
            _Thumb(name: item.name, size: 44),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: AppTextTheme.body.copyWith(
                      color: t.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    option.label,
                    style: AppTextTheme.hint.copyWith(color: t.textMuted),
                  ),
                ],
              ),
            ),
            Text(
              option.selling?.format() ?? context.l10n.priceMissing,
              style: AppTextTheme.price.copyWith(color: t.textPrimary),
            ),
            Icon(Icons.chevron_right_rounded, color: t.textMuted),
          ],
        ),
      ),
    );
  }
}

/// The Item's first letter on a muted square, as on Home.
class _Thumb extends StatelessWidget {
  const _Thumb({required this.name, this.size = 56});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: t.surfaceMuted,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        name.isEmpty ? '' : String.fromCharCode(name.runes.first),
        style: AppTextTheme.pageTitle.copyWith(color: t.textMuted),
      ),
    );
  }
}
