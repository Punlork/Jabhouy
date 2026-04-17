import 'package:flutter/material.dart';
import 'package:my_app/app/app.dart';
import 'package:my_app/l10n/arb/app_localizations.dart';
import 'package:my_app/shop/views/shop_item_form_controller.dart';

class ShopItemVariantBuilder extends StatelessWidget {
  const ShopItemVariantBuilder({
    required this.variants,
    required this.onAddSingle,
    required this.onAddPack,
    required this.onAddCustom,
    required this.onRemove,
    this.allowMultiple = true,
    super.key,
  });

  final List<ShopItemVariantDraft> variants;
  final VoidCallback onAddSingle;
  final VoidCallback onAddPack;
  final VoidCallback onAddCustom;
  final ValueChanged<ShopItemVariantDraft> onRemove;
  final bool allowMultiple;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.variants,
          style: AppTextTheme.body,
        ),
        const SizedBox(height: 8),
        if (allowMultiple) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _PresetChip(label: l10n.singleItem, onPressed: onAddSingle),
              _PresetChip(label: l10n.packItem, onPressed: onAddPack),
              _PresetChip(
                label: l10n.addVariant,
                icon: Icons.add_rounded,
                onPressed: onAddCustom,
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        ...variants.map(
          (draft) => _VariantDraftCard(
            key: draft.key,
            draft: draft,
            onRemove: allowMultiple ? () => onRemove(draft) : null,
          ),
        ),
      ],
    );
  }
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ActionChip(
      avatar: icon == null ? null : Icon(icon, size: 16),
      label: Text(label),
      onPressed: onPressed,
      side: BorderSide(color: colorScheme.outlineVariant),
      backgroundColor: colorScheme.surfaceContainerLow,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _VariantDraftCard extends StatelessWidget {
  const _VariantDraftCard({
    required this.draft,
    this.onRemove,
    super.key,
  });

  final ShopItemVariantDraft draft;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final label = draft.labelController.text.trim();
    final packAmount = int.tryParse(draft.packAmountController.text.trim());
    final title = label.isNotEmpty
        ? label
        : (packAmount != null && packAmount > 1
            ? l10n.packItem
            : l10n.singleItem);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppTextTheme.body.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (onRemove != null)
                IconButton(
                  onPressed: onRemove,
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: _VariantInput(
                  controller: draft.labelController,
                  label: l10n.variantLabel,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _VariantInput(
                  controller: draft.packAmountController,
                  label: l10n.packSize,
                  suffixText: l10n.itemsSuffix,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return null;
                    }
                    final parsed = int.tryParse(value);
                    if (parsed == null || parsed < 1) {
                      return l10n.packSizeValidation;
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _VariantInput(
                  controller: draft.customerPriceController,
                  label: l10n.customerPrice,
                  suffixText: 'រៀល',
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n.nameRequired(l10n.customerPrice);
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _VariantInput(
                  controller: draft.defaultPriceController,
                  label: l10n.defaultPrice,
                  suffixText: 'រៀល',
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _VariantInput(
                  controller: draft.sellerPriceController,
                  label: l10n.sellerPrice,
                  suffixText: 'រៀល',
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _VariantInput extends StatelessWidget {
  const _VariantInput({
    required this.controller,
    required this.label,
    this.suffixText,
    this.validator,
    this.keyboardType = TextInputType.text,
  });

  final TextEditingController controller;
  final String label;
  final String? suffixText;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        isDense: true,
        labelText: label,
        suffixText: suffixText,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
      ),
    );
  }
}
