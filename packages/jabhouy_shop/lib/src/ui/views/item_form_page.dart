import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jabhouy_core/jabhouy_core.dart';
import 'package:jabhouy_l10n/jabhouy_l10n.dart';
import 'package:jabhouy_shop/src/models/item_draft.dart';
import 'package:jabhouy_shop/src/ui/bloc/item_form/item_form_cubit.dart';
import 'package:jabhouy_shop/src/ui/widgets/category_picker_sheet.dart';
import 'package:jabhouy_shop/src/ui/widgets/price_row_editor.dart';
import 'package:jabhouy_shop/src/ui/widgets/text_prompt_dialog.dart';
import 'package:jabhouy_ui/jabhouy_ui.dart';

/// Add or edit an Item with its Price options (canvas ៣, ៤, ៤ខ, ៤គ).
/// Expects an [ItemFormCubit] above it; edits when the cubit has
/// `existing`. Pops once saved.
class ItemFormPage extends StatefulWidget {
  const ItemFormPage({this.scanBarcode, this.barcode, super.key});

  /// Opens the scanner for a row's barcode; null hides the button (flag
  /// off).
  final Future<String?> Function(BuildContext context)? scanBarcode;

  /// A scanned code nobody uses yet: a new Item's first row starts with it.
  final String? barcode;

  static const nameKey = Key('item-form-name');

  @override
  State<ItemFormPage> createState() => _ItemFormPageState();
}

class _ItemFormPageState extends State<ItemFormPage> {
  late final _cubit = context.read<ItemFormCubit>();
  late final _id = _cubit.existing?.id ?? newId();
  late final _name = TextEditingController(text: _cubit.existing?.name);
  late final _note = TextEditingController(text: _cubit.existing?.note);
  late final _nicknames = [...?_cubit.existing?.nicknames];
  late final List<PriceRowDraft> _rows = [
    ...?_cubit.existing?.prices.map(PriceRowDraft.from),
  ];

  /// The one price row open for editing; the rest show as summaries.
  /// A single row (a new item, or an item with one price) starts open.
  late String? _openRowId = _rows.length == 1 ? _rows.single.id : null;

  /// Scroll targets for the first problem: `name`, `rows`, or a row id.
  final _keys = <String, GlobalKey>{};
  GlobalKey _keyFor(String id) => _keys.putIfAbsent(id, GlobalKey.new);

  @override
  void dispose() {
    _name.dispose();
    _note.dispose();
    super.dispose();
  }

  PriceRowDraft _emptyRow(ItemFormState state) => PriceRowDraft(
    id: newId(),
    currency: state.settings.currency,
    barcode: widget.barcode,
  );

  void _save(ItemFormState state) {
    FocusScope.of(context).unfocus();
    _cubit.save(
      ItemDraft(
        id: _id,
        name: _name.text,
        nicknames: _nicknames,
        categoryId: state.categoryId,
        note: _note.text,
        rows: _rows,
      ),
    );
  }

  void _showFirstProblem(Map<String, FormProblem> problems) {
    final order = ['name', 'rows', for (final row in _rows) row.id];
    for (final id in order) {
      final hit = problems.keys.any((k) => k == id || k.startsWith('$id.'));
      final target = _keys[id]?.currentContext;
      if (hit && target != null) {
        Scrollable.ensureVisible(
          target,
          duration: const Duration(milliseconds: 250),
        );
        return;
      }
    }
  }

  Future<void> _addNickname() async {
    final l10n = context.l10n;
    final name = await showTextPrompt(
      context,
      title: l10n.itemNicknames,
      hintText: l10n.itemAddNicknameExample,
    );
    final trimmed = name?.trim() ?? '';
    if (trimmed.isEmpty || _nicknames.contains(trimmed)) return;
    setState(() => _nicknames.add(trimmed));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final t = context.tokens;
    return BlocConsumer<ItemFormCubit, ItemFormState>(
      listenWhen: (a, b) => a.status != b.status || a.problems != b.problems,
      listener: (context, state) {
        if (state.status == ItemFormStatus.ready && _rows.isEmpty) {
          final row = _emptyRow(state);
          setState(() {
            _rows.add(row);
            _openRowId = row.id;
          });
        }
        if (state.status == ItemFormStatus.saved) {
          Navigator.of(context).maybePop();
        }
        if (state.problems.isNotEmpty) {
          // Open the first row with a problem so its message shows.
          final bad = _rows.where(
            (r) => state.problems.keys.any((k) => k.startsWith('${r.id}.')),
          );
          if (bad.isNotEmpty) setState(() => _openRowId = bad.first.id);
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => _showFirstProblem(state.problems),
          );
        }
      },
      builder: (context, state) {
        final loading = state.status == ItemFormStatus.loading;
        return Scaffold(
          backgroundColor: t.bg,
          appBar: AppBar(
            centerTitle: false,
            leading: IconButton(
              onPressed: () => Navigator.of(context).maybePop(),
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            title: Text(_cubit.existing == null ? l10n.itemAdd : l10n.itemEdit),
          ),
          body: loading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  children: [
                    _nameSection(state),
                    const SizedBox(height: AppSizes.sectionGap),
                    _categorySection(state),
                    const SizedBox(height: AppSizes.sectionGap),
                    _priceSection(state),
                    const SizedBox(height: AppSizes.sectionGap),
                    LabeledField(
                      label: l10n.noteLabel,
                      optional: true,
                      child: TextField(
                        controller: _note,
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText: l10n.itemNoteHint,
                        ),
                      ),
                    ),
                  ],
                ),
          bottomNavigationBar: SafeArea(
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              decoration: BoxDecoration(
                color: t.bg,
                border: Border(top: BorderSide(color: t.dividerStrong)),
              ),
              child: SizedBox(
                height: AppSizes.buttonHeight,
                child: FilledButton(
                  // Never disabled: problems show on save (plan §5.3).
                  onPressed: loading ? null : () => _save(state),
                  child: Text(l10n.save),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _nameSection(ItemFormState state) {
    final l10n = context.l10n;
    final t = context.tokens;
    final nameProblem = state.problems['name'];
    return Column(
      key: _keyFor('name'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LabeledField(
          label: l10n.itemName,
          child: TextField(
            key: ItemFormPage.nameKey,
            controller: _name,
            onChanged: _cubit.nameChanged,
            decoration: InputDecoration(
              hintText: l10n.itemNameHint,
              error: nameProblem == null ? null : const SizedBox(),
            ),
          ),
        ),
        if (nameProblem != null) ...[
          const SizedBox(height: AppSizes.fieldGap),
          ErrorLine(problemText(l10n, nameProblem)),
        ],
        if (state.duplicateOf != null) ...[
          const SizedBox(height: AppSizes.fieldGap),
          Text(
            '${l10n.itemDuplicateName} · ${l10n.itemSaveAsNew}',
            style: AppTextTheme.hint.copyWith(
              color: t.warningText,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        const SizedBox(height: 12),
        Text.rich(
          TextSpan(
            text: l10n.itemNicknames,
            children: [
              TextSpan(
                text: ' (${l10n.itemNicknamesHint})',
                style: TextStyle(color: t.textMuted),
              ),
            ],
          ),
          style: AppTextTheme.hint.copyWith(color: t.textSecondary),
        ),
        const SizedBox(height: AppSizes.fieldGap),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final nickname in _nicknames)
              InputChip(
                label: Text(nickname),
                backgroundColor: t.surfaceMuted,
                side: BorderSide.none,
                shape: const StadiumBorder(),
                deleteIcon: const Icon(Icons.close_rounded, size: 14),
                onDeleted: () => setState(() => _nicknames.remove(nickname)),
              ),
            // shortcut: solid border where the canvas draws a dashed one;
            // Flutter has no dashed border without a package.
            ActionChip(
              onPressed: _addNickname,
              backgroundColor: Colors.transparent,
              side: BorderSide(color: t.border),
              shape: const StadiumBorder(),
              label: Text.rich(
                TextSpan(
                  text: l10n.itemAddNickname,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  children: [
                    TextSpan(
                      text: ' (${l10n.itemAddNicknameExample})',
                      style: TextStyle(
                        color: t.textMuted,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _openCategoryPicker(ItemFormState state) async {
    final picked = await showCategoryPicker(
      context,
      categories: state.categories,
      selectedId: state.categoryId,
      onCreate: (name) async {
        await _cubit.createCategory(name);
        return _cubit.state.categoryId!;
      },
    );
    if (picked != null && picked != _cubit.state.categoryId) {
      await _cubit.pickCategory(picked);
    }
  }

  Widget _categorySection(ItemFormState state) {
    final l10n = context.l10n;
    final t = context.tokens;
    final visible = state.categories.where((c) => !c.hidden).toList();
    final selected = visible.where((c) => c.id == state.categoryId);
    // The chosen category first, then the rest, five at most (canvas ៤ក).
    final chips = [
      ...selected,
      ...visible.where((c) => c.id != state.categoryId),
    ].take(5).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.category,
          style: AppTextTheme.sectionTitle.copyWith(color: t.textPrimary),
        ),
        const SizedBox(height: 10),
        QuickPickChips(
          options: [for (final c in chips) c.name],
          selected: selected.isEmpty ? null : selected.first.name,
          onPick: (name) =>
              _cubit.pickCategory(chips.firstWhere((c) => c.name == name).id),
          trailing: InkWell(
            onTap: () => _openCategoryPicker(state),
            borderRadius: BorderRadius.circular(AppSizes.radiusChip),
            child: SizedBox(
              height: AppSizes.minTapTarget,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.all,
                      style: AppTextTheme.label.copyWith(
                        color: t.textSecondary,
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: t.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSizes.fieldGap),
        Text(
          state.suggested ? l10n.categorySuggested : l10n.categoryHint,
          style: AppTextTheme.hint.copyWith(color: t.textMuted),
        ),
      ],
    );
  }

  Widget _priceSection(ItemFormState state) {
    final l10n = context.l10n;
    final t = context.tokens;
    final category = state.categories.where((c) => c.id == state.categoryId);
    return Column(
      key: _keyFor('rows'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.priceSection,
          style: AppTextTheme.sectionTitle.copyWith(color: t.textPrimary),
        ),
        const SizedBox(height: 10),
        for (final (i, row) in _rows.indexed)
          Container(
            key: _keyFor(row.id),
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: t.dividerStrong)),
            ),
            child: row.id != _openRowId
                ? PriceRowSummary(
                    draft: row,
                    hasProblem: state.problems.keys.any(
                      (k) => k.startsWith('${row.id}.'),
                    ),
                    onTap: () => setState(() => _openRowId = row.id),
                  )
                // The header stays on top to close the row; column labels
                // belong to the open row's fields only.
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      PriceRowSummary(
                        draft: row,
                        expanded: true,
                        onTap: () => setState(() => _openRowId = null),
                      ),
                      const SizedBox(height: 8),
                      const PriceRowHeader(),
                      const SizedBox(height: AppSizes.fieldGap),
                      PriceRowEditor(
                        key: ValueKey(row.id),
                        initial: row,
                        settings: state.settings,
                        problems: {
                          for (final MapEntry(:key, :value)
                              in state.problems.entries)
                            if (key.startsWith('${row.id}.'))
                              key.substring(row.id.length + 1): value,
                        },
                        unitChips: state.units,
                        unitHint: category.isNotEmpty
                            ? l10n.priceUnitsFor(category.first.name)
                            : null,
                        // Rebuild so the header follows what is typed.
                        onChanged: (draft) => setState(
                          () =>
                              _rows[_rows.indexWhere((r) => r.id == draft.id)] =
                                  draft,
                        ),
                        onScan: switch (widget.scanBarcode) {
                          final scan? => () => scan(context),
                          null => null,
                        },
                        onRemove: _rows.length > 1
                            ? () => setState(() => _rows.removeAt(i))
                            : null,
                      ),
                    ],
                  ),
          ),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: InkWell(
            onTap: () {
              final row = _emptyRow(state);
              setState(() {
                _rows.add(row);
                _openRowId = row.id;
              });
            },
            child: SizedBox(
              height: AppSizes.minTapTarget,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_rounded, size: 18, color: t.textPrimary),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text.rich(
                      TextSpan(
                        text: '${l10n.priceAdd} ',
                        children: [
                          TextSpan(
                            text: '(${l10n.priceAddExample})',
                            style: TextStyle(
                              color: t.textMuted,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                      style: AppTextTheme.label.copyWith(
                        color: t.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
