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
      ProblemKind.packQtyNotPositive => l10n.pricePackPositive,
      ProblemKind.barcodeUsed => l10n.priceBarcodeUsed(problem.itemName ?? ''),
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
    this.onScan,
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

  /// Reads a barcode for this row; null hides the button (flag off).
  final Future<String?> Function()? onScan;

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

  /// Wholesale and cost follow the row's currency: when the price
  /// switches, their amounts convert too, as the price's does.
  void _convertSecondary(Currency to) {
    for (final c in [_wholesale, _cost]) {
      final money = Money.tryParse(c.text, _draft.currency);
      c.text =
          money
              ?.convertTo(to, khrPerUsd: widget.settings.khrPerUsd)
              .formatNumber() ??
          '';
    }
  }

  void _update({
    String? unit,
    String? packQty,
    String? price,
    Currency? currency,
    String? wholesale,
    String? cost,
    String? barcode,
  }) {
    _draft = PriceRowDraft(
      id: _draft.id,
      currency: currency ?? _draft.currency,
      unit: unit ?? _draft.unit,
      packQty: packQty ?? _draft.packQty,
      price: price ?? _draft.price,
      wholesale: wholesale ?? _draft.wholesale,
      cost: cost ?? _draft.cost,
      barcode: barcode ?? _draft.barcode,
    );
    widget.onChanged(_draft);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final t = context.tokens;
    final problems = widget.problems;
    final settings = widget.settings;
    // The remove button sits on this line: on the price line it left the
    // price field too narrow to read.
    final showQuiet =
        settings.useWholesale ||
        settings.useCost ||
        widget.onRemove != null ||
        widget.onScan != null;
    // Each message sits under the line its field is on.
    List<Widget> errorsFor(List<String> fields) => [
      for (final field in fields)
        if (problems[field] case final problem?)
          Padding(
            padding: const EdgeInsets.only(top: AppSizes.fieldGap),
            child: ErrorLine(problemText(l10n, problem)),
          ),
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
                      vertical: 13,
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
                onText: (text, currency) => setState(() {
                  if (currency != _draft.currency) _convertSecondary(currency);
                  _update(
                    price: text,
                    currency: currency,
                    wholesale: _wholesale.text,
                    cost: _cost.text,
                  );
                }),
                hasError: problems.containsKey('price'),
              ),
            ),
          ],
        ),
        ...errorsFor(['unit', 'packQty', 'price']),
        if (showQuiet) ...[
          const SizedBox(height: _gap),
          Row(
            children: [
              if (settings.useWholesale) ...[
                Expanded(
                  child: _QuietField(
                    label: l10n.priceWholesaleShort,
                    semanticLabel: l10n.priceWholesale,
                    currency: _draft.currency,
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
                    currency: _draft.currency,
                    controller: _cost,
                    hasError: problems.containsKey('cost'),
                    onChanged: (v) => _update(cost: v),
                  ),
                ),
              if (!settings.useWholesale && !settings.useCost) const Spacer(),
              if (widget.onScan case final scan?) ...[
                const SizedBox(width: _gap),
                _BarcodeButton(
                  attached: _draft.barcode?.isNotEmpty ?? false,
                  hasError: problems.containsKey('barcode'),
                  onPressed: () async {
                    final code = await scan();
                    if (code != null && mounted) {
                      setState(() => _update(barcode: code));
                    }
                  },
                ),
              ],
              if (widget.onRemove != null)
                IconButton(
                  onPressed: widget.onRemove,
                  tooltip: l10n.priceRemove,
                  icon: Icon(Icons.close_rounded, size: 20, color: t.textMuted),
                ),
            ],
          ),
        ],
        ...errorsFor(['wholesale', 'cost', 'barcode']),
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

/// A price row's header: `1 កេះ · ×12   12,222 ៛  ▾`, then wholesale and
/// cost when set. Tapping it opens or closes the row.
class PriceRowSummary extends StatelessWidget {
  const PriceRowSummary({
    required this.draft,
    required this.onTap,
    this.expanded = false,
    this.hasProblem = false,
    super.key,
  });

  final PriceRowDraft draft;
  final VoidCallback onTap;

  /// The row's fields show below this header.
  final bool expanded;

  /// Outlined in red: the row holds a save-time problem.
  final bool hasProblem;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final t = context.tokens;
    final muted = AppTextTheme.hint.copyWith(color: t.textMuted);
    final extras = [
      for (final (label, text) in [
        (l10n.priceWholesaleLabel, draft.wholesale),
        (l10n.priceCostShort, draft.cost),
      ])
        if (Money.tryParse(text, draft.currency) case final money?)
          '$label ${money.format()}',
    ];

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.radiusInput),
      child: Container(
        constraints: const BoxConstraints(minHeight: AppSizes.minTapTarget),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        decoration: hasProblem
            ? BoxDecoration(
                border: Border.all(color: t.dangerText, width: 2),
                borderRadius: BorderRadius.circular(AppSizes.radiusInput),
              )
            : null,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Baseline: unit and price differ in size and script, so
                  // centring their boxes leaves them visibly off.
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Expanded(
                        child: Text(
                          unitLabel(
                            draft.unit,
                            parseWholeNumber(draft.packQty),
                          ),
                          style: AppTextTheme.body.copyWith(
                            color: t.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      PriceDisplay(
                        price: Money.tryParse(draft.price, draft.currency),
                        // Unused: the summary shows no converted line.
                        khrPerUsd: 0,
                        showConverted: false,
                      ),
                    ],
                  ),
                  if (extras.isNotEmpty) Text(extras.join(' · '), style: muted),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Centred on the first line (price 17 px × 1.5), not on both.
            SizedBox(
              height: 26,
              child: Center(
                child: Icon(
                  expanded
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded,
                  color: t.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Secondary price field (canvas ៣ខ): an underline, label inside, the
/// row's currency at the end. 44 tall so it stays a valid tap target.
class _QuietField extends StatelessWidget {
  const _QuietField({
    required this.label,
    required this.semanticLabel,
    required this.currency,
    required this.controller,
    required this.hasError,
    required this.onChanged,
  });

  final String label;
  final String semanticLabel;
  final Currency currency;
  final TextEditingController controller;
  final bool hasError;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final muted = AppTextTheme.hint.copyWith(color: t.textMuted);
    return Container(
      height: AppSizes.minTapTarget,
      // Centres the baseline-aligned row vertically in the 44 px box.
      alignment: AlignmentDirectional.centerStart,
      padding: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        border: Border(
          bottom: hasError
              ? BorderSide(color: t.dangerText, width: 2)
              : BorderSide(
                  color: t.textMuted.withValues(alpha: 0.5),
                  width: 1.5,
                ),
        ),
      ),
      // Baseline, not centre: Khmer and Latin glyphs sit at different
      // heights, so centring the boxes leaves the number looking off.
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(label, style: muted),
          const SizedBox(width: 6),
          Expanded(
            child: Semantics(
              label: semanticLabel,
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                keyboardType: moneyKeyboard(currency),
                inputFormatters: moneyFormatters(currency),
                style: AppTextTheme.hint.copyWith(color: t.textPrimary),
                // The app theme fills and outlines every field; this one
                // draws only its underline, so turn both off here.
                decoration: InputDecoration(
                  isCollapsed: true,
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  hintText: '0',
                  hintStyle: AppTextTheme.hint.copyWith(color: t.placeholder),
                ),
              ),
            ),
          ),
          Text(
            currency == Currency.khr ? '៛' : r'$',
            style: muted.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

/// 44×44 barcode button (canvas ៤ខ): outlined with none, dark once a
/// code is attached, red when that code is used by another Item.
class _BarcodeButton extends StatelessWidget {
  const _BarcodeButton({
    required this.attached,
    required this.hasError,
    required this.onPressed,
  });

  final bool attached;
  final bool hasError;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final fg = hasError
        ? t.dangerText
        : attached
        ? t.onPrimary
        : t.textPrimary;
    return SizedBox.square(
      dimension: 44,
      child: IconButton(
        onPressed: onPressed,
        tooltip: context.l10n.scanTitle,
        style: IconButton.styleFrom(
          backgroundColor: attached && !hasError ? t.textPrimary : t.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: hasError
                ? BorderSide(color: t.dangerText, width: 2)
                : attached
                ? BorderSide.none
                : BorderSide(color: t.border),
          ),
        ),
        icon: Icon(Icons.qr_code_scanner_rounded, size: 20, color: fg),
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
