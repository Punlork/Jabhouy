import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jabhouy_core/jabhouy_core.dart';
import 'package:jabhouy_l10n/jabhouy_l10n.dart';
import 'package:jabhouy_shop/src/models/item_draft.dart';
import 'package:jabhouy_shop/src/ui/bloc/item_form/item_form_cubit.dart';
import 'package:jabhouy_shop/src/ui/widgets/price_row_editor.dart';
import 'package:jabhouy_ui/jabhouy_ui.dart';

/// Add or edit an Item with its Price options (canvas ៣, ៤, ៤ខ, ៤គ).
/// Expects an [ItemFormCubit] above it; edits when the cubit has
/// `existing`. Pops once saved.
class ItemFormPage extends StatefulWidget {
  const ItemFormPage({super.key});

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

  /// Scroll targets for the first problem: `name`, `rows`, or a row id.
  final _keys = <String, GlobalKey>{};
  GlobalKey _keyFor(String id) => _keys.putIfAbsent(id, GlobalKey.new);

  @override
  void dispose() {
    _name.dispose();
    _note.dispose();
    super.dispose();
  }

  PriceRowDraft _emptyRow(ItemFormState state) =>
      PriceRowDraft(id: newId(), currency: state.settings.currency);

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
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.itemNicknames),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(hintText: l10n.itemAddNicknameExample),
          onSubmitted: (v) => Navigator.pop(context, v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text(l10n.save),
          ),
        ],
      ),
    );
    controller.dispose();
    final trimmed = name?.trim() ?? '';
    if (trimmed.isEmpty || _nicknames.contains(trimmed)) return;
    setState(() => _nicknames.add(trimmed));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final t = context.tokens;
    return BlocConsumer<ItemFormCubit, ItemFormState>(
      listenWhen: (a, b) =>
          a.status != b.status || a.problems != b.problems,
      listener: (context, state) {
        if (state.status == ItemFormStatus.ready && _rows.isEmpty) {
          setState(() => _rows.add(_emptyRow(state)));
        }
        if (state.status == ItemFormStatus.saved) {
          Navigator.of(context).maybePop();
        }
        if (state.problems.isNotEmpty) _showFirstProblem(state.problems);
      },
      builder: (context, state) {
        final loading = state.status == ItemFormStatus.loading;
        return Scaffold(
          backgroundColor: t.bg,
          appBar: AppBar(
            title: Text(
              _cubit.existing == null ? l10n.itemAdd : l10n.itemEdit,
            ),
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
                      child: TextField(controller: _note, maxLines: 2),
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
              errorText: nameProblem == null
                  ? null
                  : problemText(l10n, nameProblem),
            ),
          ),
        ),
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
                onDeleted: () => setState(() => _nicknames.remove(nickname)),
              ),
            ActionChip(
              label: Text(l10n.itemAddNickname),
              onPressed: _addNickname,
            ),
          ],
        ),
      ],
    );
  }

  Widget _categorySection(ItemFormState state) {
    final l10n = context.l10n;
    final t = context.tokens;
    final visible = state.categories.where((c) => !c.hidden).toList();
    final selected = visible.where((c) => c.id == state.categoryId);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.category,
          style: AppTextTheme.sectionTitle.copyWith(color: t.textPrimary),
        ),
        const SizedBox(height: 10),
        // shortcut: every category as a chip; issue 16's picker adds
        // `ទាំងអស់ ›` and trims this to the top few.
        QuickPickChips(
          options: [for (final c in visible) c.name],
          selected: selected.isEmpty ? null : selected.first.name,
          onPick: (name) => _cubit.pickCategory(
            visible.firstWhere((c) => c.name == name).id,
          ),
        ),
        if (state.suggested) ...[
          const SizedBox(height: AppSizes.fieldGap),
          Text(
            l10n.categorySuggested,
            style: AppTextTheme.hint.copyWith(color: t.textMuted),
          ),
        ],
      ],
    );
  }

  Widget _priceSection(ItemFormState state) {
    final l10n = context.l10n;
    final t = context.tokens;
    final category = state.categories.where((c) => c.id == state.categoryId);
    final rowsProblem = state.problems['rows'];
    return Column(
      key: _keyFor('rows'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.priceSection,
          style: AppTextTheme.sectionTitle.copyWith(color: t.textPrimary),
        ),
        const SizedBox(height: 10),
        const PriceRowHeader(),
        const SizedBox(height: AppSizes.fieldGap),
        for (final (i, row) in _rows.indexed)
          Padding(
            key: _keyFor(row.id),
            padding: const EdgeInsets.only(bottom: 16),
            child: PriceRowEditor(
              key: ValueKey(row.id),
              initial: row,
              settings: state.settings,
              problems: {
                for (final MapEntry(:key, :value) in state.problems.entries)
                  if (key.startsWith('${row.id}.'))
                    key.substring(row.id.length + 1): value,
              },
              unitChips: i == 0 ? state.units : const [],
              unitHint: i == 0 && category.isNotEmpty
                  ? l10n.priceUnitsFor(category.first.name)
                  : null,
              onChanged: (draft) => _rows[_rows.indexWhere(
                (r) => r.id == draft.id,
              )] = draft,
              onRemove: _rows.length > 1
                  ? () => setState(() => _rows.removeAt(i))
                  : null,
            ),
          ),
        if (rowsProblem != null) ErrorLine(problemText(l10n, rowsProblem)),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton.icon(
            onPressed: () => setState(() => _rows.add(_emptyRow(state))),
            icon: const Icon(Icons.add),
            label: Text.rich(
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
            ),
          ),
        ),
      ],
    );
  }
}
