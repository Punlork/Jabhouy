import 'package:flutter/material.dart';
import 'package:jabhouy_l10n/jabhouy_l10n.dart';
import 'package:jabhouy_shop/src/ui/views/shop_item_form_controller.dart';
import 'package:jabhouy_shop/src/ui/widgets/whole_number_input.dart';
import 'package:jabhouy_ui/jabhouy_ui.dart';

const _currency = 'រៀល';

/// The variant cards of the shop item form.
///
/// On create there may be several, and a card that could save collapses
/// to one line. On edit there is exactly one, and it stays open.
class ShopItemVariantBuilder extends StatelessWidget {
  const ShopItemVariantBuilder({
    required this.variants,
    required this.onAddSingle,
    required this.onAddPack,
    required this.onRemove,
    required this.onPackChanged,
    required this.onExpandedChanged,
    this.allowMultiple = true,
    super.key,
  });

  final List<ShopItemVariantDraft> variants;
  final VoidCallback onAddSingle;
  final VoidCallback onAddPack;
  final ValueChanged<ShopItemVariantDraft> onRemove;
  final void Function(ShopItemVariantDraft draft, {required bool isPack})
      onPackChanged;
  final void Function(ShopItemVariantDraft draft, {required bool isExpanded})
      onExpandedChanged;

  /// False on edit: one card, no chips, no ✕, no collapsing.
  final bool allowMultiple;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.variants, style: AppTextTheme.body),
        const SizedBox(height: 8),
        if (allowMultiple) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _PresetChip(label: l10n.singleItem, onPressed: onAddSingle),
              _PresetChip(label: l10n.packItem, onPressed: onAddPack),
            ],
          ),
          const SizedBox(height: 8),
        ],
        for (final draft in variants)
          _VariantDraftCard(
            key: draft.key,
            draft: draft,
            collapsible: allowMultiple,
            onRemove: allowMultiple ? () => onRemove(draft) : null,
            onPackChanged: (isPack) => onPackChanged(draft, isPack: isPack),
            onExpandedChanged: (isExpanded) =>
                onExpandedChanged(draft, isExpanded: isExpanded),
          ),
      ],
    );
  }
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ActionChip(
      avatar: const Icon(Icons.add_rounded, size: 16),
      label: Text(label),
      onPressed: onPressed,
      side: BorderSide(color: colorScheme.outlineVariant),
      backgroundColor: colorScheme.surfaceContainerLow,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      visualDensity: VisualDensity.compact,
    );
  }
}

String _problemMessage(AppLocalizations l10n, VariantProblem problem) {
  return switch (problem) {
    VariantProblem.missingCustomerPrice =>
      l10n.nameRequired(l10n.customerPrice),
    VariantProblem.invalidPrice => l10n.invalidPrice,
    VariantProblem.invalidPackSize => l10n.packSizeValidation,
  };
}

class _VariantDraftCard extends StatelessWidget {
  const _VariantDraftCard({
    required this.draft,
    required this.collapsible,
    required this.onPackChanged,
    required this.onExpandedChanged,
    this.onRemove,
    super.key,
  });

  final ShopItemVariantDraft draft;
  final bool collapsible;
  final ValueChanged<bool> onPackChanged;
  final ValueChanged<bool> onExpandedChanged;
  final VoidCallback? onRemove;

  bool get _collapsed => collapsible && !draft.isExpanded;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 180),
        alignment: Alignment.topCenter,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _header(context),
            // Offstage, not removed: Form.validate() only checks fields
            // that are mounted, and a collapsed card must still block a
            // save it cannot pass.
            Offstage(offstage: _collapsed, child: _fields(context)),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final material = MaterialLocalizations.of(context);

    final Widget lead;
    if (_collapsed) {
      final problems = draft.problems;
      lead = InkWell(
        onTap: () => onExpandedChanged(true),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            problems.isEmpty
                ? _summary(l10n)
                : '⚠ ${_problemMessage(l10n, problems.first)}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextTheme.body.copyWith(
              color: problems.isEmpty
                  ? colorScheme.onSurface
                  : colorScheme.error,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    } else {
      lead = Wrap(
        spacing: 8,
        children: [
          ChoiceChip(
            label: Text(l10n.singleItem),
            selected: !draft.isPack,
            onSelected: (_) => onPackChanged(false),
            visualDensity: VisualDensity.compact,
          ),
          ChoiceChip(
            label: Text(l10n.packItem),
            selected: draft.isPack,
            onSelected: (_) => onPackChanged(true),
            visualDensity: VisualDensity.compact,
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: lead),
        if (collapsible)
          IconButton(
            onPressed: () => onExpandedChanged(!draft.isExpanded),
            tooltip: draft.isExpanded
                ? material.expandedIconTapHint
                : material.collapsedIconTapHint,
            visualDensity: VisualDensity.compact,
            icon: Icon(
              draft.isExpanded
                  ? Icons.expand_less_rounded
                  : Icons.expand_more_rounded,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        if (onRemove != null)
          IconButton(
            onPressed: onRemove,
            visualDensity: VisualDensity.compact,
            icon: Icon(
              Icons.close_rounded,
              size: 18,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }

  /// `Pack · Pack Can · ×24 · 400 រៀល`
  String _summary(AppLocalizations l10n) {
    final label = draft.labelController.text.trim();
    final price = parseWholeNumber(draft.customerPriceController.text);
    final pack = parseWholeNumber(draft.packAmountController.text);
    return [
      if (draft.isPack) l10n.packItem else l10n.singleItem,
      if (label.isNotEmpty) label,
      if (draft.isPack && pack != null) '×$pack',
      if (price != null) '$price $_currency',
    ].join(' · ');
  }

  Widget _fields(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    String? optionalPrice(String? value) =>
        (value ?? '').trim().isNotEmpty && parseWholeNumber(value!) == null
            ? l10n.invalidPrice
            : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        _LabeledInput(
          controller: draft.labelController,
          label: l10n.variantLabel,
        ),
        if (draft.isPack) ...[
          const SizedBox(height: 12),
          _LabeledInput(
            controller: draft.packAmountController,
            label: l10n.packSize,
            suffixText: l10n.itemsSuffix,
            wholeNumber: true,
            validator: (value) =>
                (parseWholeNumber(value ?? '') ?? 0) < 2
                    ? l10n.packSizeValidation
                    : null,
          ),
        ],
        const SizedBox(height: 12),
        _LabeledInput(
          controller: draft.customerPriceController,
          label: l10n.customerPrice,
          required: true,
          suffixText: _currency,
          wholeNumber: true,
          validator: (value) {
            if ((value ?? '').trim().isEmpty) {
              return l10n.nameRequired(l10n.customerPrice);
            }
            return optionalPrice(value);
          },
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _LabeledInput(
                controller: draft.defaultPriceController,
                label: l10n.defaultPrice,
                suffixText: _currency,
                wholeNumber: true,
                validator: optionalPrice,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _LabeledInput(
                controller: draft.sellerPriceController,
                label: l10n.sellerPrice,
                suffixText: _currency,
                wholeNumber: true,
                validator: optionalPrice,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// A label above its field, at body size.
///
/// Khmer script is tall; a floating label shrunk into a dense border
/// became unreadable and truncated.
class _LabeledInput extends StatelessWidget {
  const _LabeledInput({
    required this.controller,
    required this.label,
    this.required = false,
    this.suffixText,
    this.validator,
    this.wholeNumber = false,
  });

  final TextEditingController controller;
  final String label;
  final bool required;
  final String? suffixText;
  final String? Function(String?)? validator;
  final bool wholeNumber;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          required ? '$label *' : label,
          style: AppTextTheme.caption.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          validator: validator,
          // Per field, not on the Form: a Form-level mode validates every
          // field once any one changes, so an untouched price went red as
          // soon as the pack size was typed. This clears a field's error
          // the moment it is fixed and leaves the rest alone until save.
          autovalidateMode: AutovalidateMode.onUserInteraction,
          keyboardType:
              wholeNumber ? TextInputType.number : TextInputType.text,
          inputFormatters: wholeNumber ? const [WholeNumberFormatter()] : null,
          decoration: InputDecoration(
            isDense: true,
            suffixText: suffixText,
            errorMaxLines: 2,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }
}
