import 'package:flutter/material.dart';
import 'package:jabhouy_l10n/jabhouy_l10n.dart';
import 'package:jabhouy_shop/src/models/item.dart';
import 'package:jabhouy_shop/src/models/item_draft.dart';
import 'package:jabhouy_shop/src/ui/widgets/price_row_editor.dart';
import 'package:jabhouy_ui/jabhouy_ui.dart';

/// What the price sheet gave back: the row to keep, or a delete.
sealed class PriceSheetResult {
  const PriceSheetResult();
}

class PriceSaved extends PriceSheetResult {
  const PriceSaved(this.draft);

  final PriceRowDraft draft;
}

class PriceDeleted extends PriceSheetResult {
  const PriceDeleted();
}

/// One Price option in a sheet (canvas ៤ក, ៣ក). [isNew] shows `បន្ថែម`;
/// otherwise `រួចរាល់` and `លុបតម្លៃនេះ`. Null when closed, or when a new
/// row was left empty: closing adds nothing.
Future<PriceSheetResult?> showPriceSheet(
  BuildContext context, {
  required PriceRowDraft initial,
  required PriceSettings settings,
  bool isNew = false,
  List<String> unitChips = const [],
  String? unitHint,
  Future<String?> Function()? onScan,
  Map<String, FormProblem> problems = const {},
}) => showFitSheet<PriceSheetResult>(
  context,
  builder: (_) => _PriceSheet(
    initial: initial,
    settings: settings,
    isNew: isNew,
    unitChips: unitChips,
    unitHint: unitHint,
    onScan: onScan,
    problems: problems,
  ),
);

class _PriceSheet extends StatefulWidget {
  const _PriceSheet({
    required this.initial,
    required this.settings,
    required this.isNew,
    required this.unitChips,
    required this.unitHint,
    required this.onScan,
    required this.problems,
  });

  final PriceRowDraft initial;
  final PriceSettings settings;
  final bool isNew;
  final List<String> unitChips;
  final String? unitHint;
  final Future<String?> Function()? onScan;
  final Map<String, FormProblem> problems;

  @override
  State<_PriceSheet> createState() => _PriceSheetState();
}

class _PriceSheetState extends State<_PriceSheet> {
  late PriceRowDraft _draft = widget.initial;
  late Map<String, FormProblem> _problems = widget.problems;

  void _confirm() {
    if (widget.isNew && _draft.isEmpty) {
      Navigator.pop(context);
      return;
    }
    final found = ItemDraft(id: '', name: '-', rows: [_draft]).validate();
    if (found.isEmpty) {
      Navigator.pop(context, PriceSaved(_draft));
      return;
    }
    // `<rowId>.<field>` -> `<field>`, as the editor reads them.
    setState(
      () => _problems = {
        for (final MapEntry(:key, :value) in found.entries)
          key.substring(_draft.id.length + 1): value,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final t = context.tokens;
    return AppSheet(
      fit: true,
      header: Row(
        children: [
          Container(
            constraints: const BoxConstraints(minWidth: 64),
            height: 46,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: t.textPrimary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              _draft.unit.trim().isEmpty ? '·' : _draft.unit.trim(),
              style: AppTextTheme.body.copyWith(
                color: t.onPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            widget.isNew ? l10n.priceNew : l10n.priceEdit,
            style: AppTextTheme.pageTitle.copyWith(color: t.textPrimary),
          ),
        ],
      ),
      footer: SizedBox(
        height: AppSizes.buttonHeight,
        child: FilledButton(
          onPressed: _confirm,
          child: Text(widget.isNew ? l10n.add : l10n.priceDone),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PriceRowEditor(
            initial: widget.initial,
            settings: widget.settings,
            problems: _problems,
            unitChips: widget.unitChips,
            unitHint: widget.unitHint,
            autofocus: widget.isNew,
            onSubmit: _confirm,
            onScan: widget.onScan,
            onChanged: (draft) => setState(() => _draft = draft),
          ),
          if (!widget.isNew)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                onPressed: () => Navigator.pop(context, const PriceDeleted()),
                style: TextButton.styleFrom(foregroundColor: t.dangerText),
                icon: const Icon(Icons.delete_outline_rounded, size: 20),
                label: Text(l10n.priceRemove),
              ),
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
