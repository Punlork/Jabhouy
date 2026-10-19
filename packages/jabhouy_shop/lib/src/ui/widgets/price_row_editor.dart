import 'package:flutter/material.dart';
import 'package:jabhouy_core/jabhouy_core.dart';
import 'package:jabhouy_l10n/jabhouy_l10n.dart';
import 'package:jabhouy_shop/src/models/item.dart';
import 'package:jabhouy_shop/src/models/item_draft.dart';
import 'package:jabhouy_shop/src/ui/widgets/whole_number_input.dart';
import 'package:jabhouy_ui/jabhouy_ui.dart';

/// The message for [problem], in the reader's language.
String problemText(AppLocalizations l10n, FormProblem problem) =>
    switch (problem.kind) {
      ProblemKind.nameRequired => l10n.itemNameMissing,
      ProblemKind.rielDecimals => l10n.priceRielNoDecimals,
      ProblemKind.usdDecimals => l10n.priceUsdTwoDecimals,
      ProblemKind.invalidNumber => l10n.priceNotNumber,
      ProblemKind.packQtyOverOne => l10n.pricePackOverOne,
      ProblemKind.barcodeUsed => l10n.priceBarcodeUsed(problem.itemName ?? ''),
      ProblemKind.noPriceRow => l10n.priceNoRow,
    };

const _unitFlex = 2;
const _priceFlex = 5;
const _countWidth = 64.0;
const _gap = 8.0;

/// Column labels shown once above the first [PriceRowEditor].
class PriceRowHeader extends StatelessWidget {
  const PriceRowHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final style = AppTextTheme.hint.copyWith(color: context.tokens.textMuted);
    return Row(
      children: [
        Expanded(
          flex: _unitFlex,
          child: Text(l10n.priceUnit, style: style),
        ),
        const SizedBox(width: _gap),
        SizedBox(
          width: _countWidth,
          child: Text(l10n.priceCount, style: style),
        ),
        const SizedBox(width: _gap),
        Expanded(
          flex: _priceFlex,
          child: Text(l10n.priceSelling, style: style),
        ),
      ],
    );
  }
}

/// One Price option being typed: unit, optional pack count, selling price,
/// and a quiet line with wholesale and cost when the Shop uses them.
/// Wholesale and cost follow the selling price's currency.
class PriceRowEditor extends StatefulWidget {
  const PriceRowEditor({
    required this.initial,
    required this.settings,
    required this.onChanged,
    this.onRemove,
    this.problems = const {},
    this.unitChips = const [],
    this.unitHint,
    super.key,
  });

  final PriceRowDraft initial;
  final PriceSettings settings;
  final ValueChanged<PriceRowDraft> onChanged;

  /// Null hides the remove button (the only row).
  final VoidCallback? onRemove;

  /// This row's problems, keyed by field: `price`, `packQty`, ….
  final Map<String, FormProblem> problems;

  /// Unit suggestions; the form passes them to its first row only.
  final List<String> unitChips;
  final String? unitHint;

  @override
  State<PriceRowEditor> createState() => _PriceRowEditorState();
}

class _PriceRowEditorState extends State<PriceRowEditor> {
  late PriceRowDraft _draft = widget.initial;
  late final _unit = TextEditingController(text: _draft.unit);
  late final _packQty = TextEditingController(text: _draft.packQty);
  late final _wholesale = TextEditingController(text: _draft.wholesale);
  late final _cost = TextEditingController(text: _draft.cost);

  @override
  void dispose() {
    for (final c in [_unit, _packQty, _wholesale, _cost]) {
      c.dispose();
    }
    super.dispose();
  }

  void _update({
    String? unit,
    String? packQty,
    String? price,
    Currency? currency,
    String? wholesale,
    String? cost,
  }) {
    _draft = PriceRowDraft(
      id: _draft.id,
      currency: currency ?? _draft.currency,
      unit: unit ?? _draft.unit,
      packQty: packQty ?? _draft.packQty,
      price: price ?? _draft.price,
      wholesale: wholesale ?? _draft.wholesale,
      cost: cost ?? _draft.cost,
      barcode: _draft.barcode,
    );
    widget.onChanged(_draft);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final t = context.tokens;
    final problems = widget.problems;
    final settings = widget.settings;
    final symbol = _draft.currency == Currency.khr ? '៛' : r'$';
    // The remove button sits on this line: on the price line it left the
    // price field too narrow to read.
    final showQuiet =
        settings.useWholesale || settings.useCost || widget.onRemove != null;
    final below = [
      for (final field in ['unit', 'packQty', 'wholesale', 'cost', 'barcode'])
        if (problems[field] case final problem?) problemText(l10n, problem),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: _unitFlex,
              child: TextField(
                controller: _unit,
                onChanged: (v) => _update(unit: v),
                decoration: InputDecoration(
                  hintText: l10n.priceUnitHint,
                  error: problems.containsKey('unit') ? const SizedBox() : null,
                ),
              ),
            ),
            const SizedBox(width: _gap),
            SizedBox(
              width: _countWidth,
              child: Semantics(
                label: '${l10n.priceCount} ${l10n.optional}',
                child: TextField(
                  controller: _packQty,
                  onChanged: (v) => _update(packQty: v),
                  keyboardType: TextInputType.number,
                  inputFormatters: const [WholeNumberFormatter()],
                  decoration: InputDecoration(
                    hintText: l10n.priceCountHint,
                    // prefixText only shows while focused; this always does.
                    prefixIcon: Padding(
                      padding: const EdgeInsetsDirectional.only(start: 12),
                      child: Text(
                        '×',
                        style: AppTextTheme.body.copyWith(color: t.textMuted),
                      ),
                    ),
                    prefixIconConstraints: const BoxConstraints(),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 14,
                    ),
                    error: problems.containsKey('packQty')
                        ? const SizedBox()
                        : null,
                  ),
                ),
              ),
            ),
            const SizedBox(width: _gap),
            Expanded(
              flex: _priceFlex,
              child: MoneyInput(
                value: Money.tryParse(_draft.price, _draft.currency),
                currency: _draft.currency,
                khrPerUsd: settings.khrPerUsd,
                hintText: l10n.priceSellingHint,
                onText: (text, currency) =>
                    setState(() => _update(price: text, currency: currency)),
                errorText: problems['price'] == null
                    ? null
                    : problemText(l10n, problems['price']!),
              ),
            ),
          ],
        ),
        if (showQuiet) ...[
          const SizedBox(height: _gap),
          Row(
            children: [
              if (settings.useWholesale) ...[
                Expanded(
                  child: _QuietField(
                    label: l10n.priceWholesaleShort,
                    semanticLabel: l10n.priceWholesale,
                    symbol: symbol,
                    controller: _wholesale,
                    hasError: problems.containsKey('wholesale'),
                    onChanged: (v) => _update(wholesale: v),
                  ),
                ),
                if (settings.useCost) const SizedBox(width: _gap),
              ],
              if (settings.useCost)
                Expanded(
                  child: _QuietField(
                    label: l10n.priceCostShort,
                    semanticLabel: l10n.priceCost,
                    symbol: symbol,
                    controller: _cost,
                    hasError: problems.containsKey('cost'),
                    onChanged: (v) => _update(cost: v),
                  ),
                ),
              if (!settings.useWholesale && !settings.useCost) const Spacer(),
              if (widget.onRemove != null)
                IconButton(
                  onPressed: widget.onRemove,
                  tooltip: l10n.priceRemove,
                  icon: Icon(Icons.close_rounded, size: 20, color: t.textMuted),
                ),
            ],
          ),
        ],
        for (final message in below)
          Padding(
            padding: const EdgeInsets.only(top: AppSizes.fieldGap),
            child: ErrorLine(message),
          ),
        if (widget.unitChips.isNotEmpty) ...[
          const SizedBox(height: 12),
          QuickPickChips(
            options: widget.unitChips,
            selected: _draft.unit,
            onPick: (unit) => setState(() {
              _unit.text = unit;
              _update(unit: unit);
            }),
          ),
          if (widget.unitHint != null) ...[
            const SizedBox(height: AppSizes.fieldGap),
            Text(
              widget.unitHint!,
              style: AppTextTheme.hint.copyWith(color: t.textMuted),
            ),
          ],
        ],
      ],
    );
  }
}

/// Secondary price field: grey fill, no border, label inside.
/// The plan draws it 40 px; it is 44 so it stays a valid tap target.
class _QuietField extends StatelessWidget {
  const _QuietField({
    required this.label,
    required this.semanticLabel,
    required this.symbol,
    required this.controller,
    required this.hasError,
    required this.onChanged,
  });

  final String label;
  final String semanticLabel;
  final String symbol;
  final TextEditingController controller;
  final bool hasError;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final muted = AppTextTheme.hint.copyWith(color: t.textMuted);
    return Container(
      height: AppSizes.minTapTarget,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: t.surfaceSubtle,
        borderRadius: BorderRadius.circular(10),
        border: hasError ? Border.all(color: t.dangerText, width: 2) : null,
      ),
      child: Row(
        children: [
          Text(label, style: muted),
          const SizedBox(width: 6),
          Expanded(
            child: Semantics(
              label: semanticLabel,
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                style: AppTextTheme.hint.copyWith(color: t.textPrimary),
                // The app theme fills and outlines every field; the quiet
                // field draws its own background, so turn both off here.
                decoration: const InputDecoration(
                  isCollapsed: true,
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
              ),
            ),
          ),
          Text(symbol, style: muted.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

/// A red message with an icon, under the field it is about.
class ErrorLine extends StatelessWidget {
  const ErrorLine(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    final color = context.tokens.dangerText;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.error_outline, size: 16, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            message,
            style: AppTextTheme.hint.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
