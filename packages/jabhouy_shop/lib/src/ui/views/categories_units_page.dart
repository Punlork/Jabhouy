import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jabhouy_l10n/jabhouy_l10n.dart';
import 'package:jabhouy_shop/src/models/item.dart';
import 'package:jabhouy_shop/src/ui/bloc/categories/categories_cubit.dart';
import 'package:jabhouy_shop/src/ui/widgets/text_prompt_dialog.dart';
import 'package:jabhouy_ui/jabhouy_ui.dart';

/// Categories & units (Settings › ហាង): every category in the Shop's
/// order, hidden ones dimmed. Drag to reorder; tap to rename, hide, or
/// show and add units. Nothing is deleted (decision 25). Expects a
/// [CategoriesCubit] above it.
class CategoriesUnitsPage extends StatelessWidget {
  const CategoriesUnitsPage({super.key});

  static const nameKey = Key('categories-units-name');

  Future<void> _create(BuildContext context) async {
    final l10n = context.l10n;
    final cubit = context.read<CategoriesCubit>();
    final name = await showTextPrompt(
      context,
      title: l10n.categoryNew,
      hintText: l10n.categoryNameHint,
    );
    if (name == null || name.trim().isEmpty) return;
    await cubit.create(name.trim());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final t = context.tokens;
    final cubit = context.read<CategoriesCubit>();
    final canEdit = cubit.canEdit;

    return BlocBuilder<CategoriesCubit, List<ItemCategory>?>(
      builder: (context, categories) {
        return Scaffold(
          backgroundColor: t.bg,
          appBar: AppBar(
            centerTitle: false,
            leading: IconButton(
              onPressed: () => Navigator.of(context).maybePop(),
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            title: Text(l10n.settingsCategoriesUnits),
          ),
          body: categories == null
              ? const Center(child: CircularProgressIndicator())
              : ReorderableListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  buildDefaultDragHandles: false,
                  itemCount: categories.length,
                  onReorderItem: cubit.move,
                  itemBuilder: (context, i) => _CategoryRow(
                    key: ValueKey(categories[i].id),
                    category: categories[i],
                    index: i,
                    first: i == 0,
                    last: i == categories.length - 1,
                    canEdit: canEdit,
                    onTap: () => _showCategorySheet(
                      context,
                      category: categories[i],
                      cubit: cubit,
                    ),
                  ),
                  footer: canEdit
                      ? Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: _NewCategoryRow(onTap: () => _create(context)),
                        )
                      : null,
                ),
        );
      },
    );
  }
}

/// One category: name, a `លាក់` tag when hidden, its units, and a drag
/// handle for those who may edit. Rows join into one rounded card.
class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.category,
    required this.index,
    required this.first,
    required this.last,
    required this.canEdit,
    required this.onTap,
    super.key,
  });

  final ItemCategory category;
  final int index;
  final bool first;
  final bool last;
  final bool canEdit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final t = context.tokens;
    const radius = Radius.circular(AppSizes.radiusCard);
    final borderRadius = BorderRadius.vertical(
      top: first ? radius : Radius.zero,
      bottom: last ? radius : Radius.zero,
    );
    final units = [
      for (final u in category.units)
        if (!u.hidden) u.unit,
    ];
    return Material(
      color: t.surface,
      borderRadius: borderRadius,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        child: Container(
          constraints: const BoxConstraints(minHeight: 56),
          padding: EdgeInsets.fromLTRB(16, 10, canEdit ? 4 : 16, 10),
          decoration: BoxDecoration(
            border: last ? null : Border(bottom: BorderSide(color: t.divider)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            category.name,
                            style: AppTextTheme.body.copyWith(
                              color: category.hidden
                                  ? t.textMuted
                                  : t.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (category.hidden) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: t.surfaceSubtle,
                              borderRadius: BorderRadius.circular(
                                AppSizes.radiusChip,
                              ),
                            ),
                            child: Text(
                              l10n.categoryHidden,
                              style: AppTextTheme.hint.copyWith(
                                color: t.textMuted,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (units.isNotEmpty)
                      Text(
                        units.join(' · '),
                        style: AppTextTheme.hint.copyWith(color: t.textMuted),
                      ),
                  ],
                ),
              ),
              if (canEdit)
                ReorderableDragStartListener(
                  index: index,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Icon(Icons.drag_handle_rounded, color: t.textMuted),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// `+ បង្កើតប្រភេទថ្មី`, styled like the category picker's create row.
class _NewCategoryRow extends StatelessWidget {
  const _NewCategoryRow({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Material(
      color: t.surface,
      borderRadius: BorderRadius.circular(AppSizes.radiusCard),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        child: SizedBox(
          height: 56,
          child: Row(
            children: [
              const SizedBox(width: 16),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: t.surfaceSubtle,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(Icons.add_rounded, size: 18, color: t.textPrimary),
              ),
              const SizedBox(width: 12),
              Text(
                context.l10n.categoryNew,
                style: AppTextTheme.body.copyWith(
                  color: t.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> _showCategorySheet(
  BuildContext context, {
  required ItemCategory category,
  required CategoriesCubit cubit,
}) => showAppSheet<void>(
  context,
  initialSize: 0.7,
  builder: (_, controller) => _CategorySheet(
    category: category,
    cubit: cubit,
    scrollController: controller,
  ),
);

/// Rename, hide, and show, hide or add units; saved together on
/// `រក្សាទុក`. A viewer sees it read-only, with no footer.
class _CategorySheet extends StatefulWidget {
  const _CategorySheet({
    required this.category,
    required this.cubit,
    this.scrollController,
  });

  final ItemCategory category;
  final CategoriesCubit cubit;
  final ScrollController? scrollController;

  @override
  State<_CategorySheet> createState() => _CategorySheetState();
}

class _CategorySheetState extends State<_CategorySheet> {
  late final _name = TextEditingController(text: widget.category.name);
  late bool _hidden = widget.category.hidden;
  late final _units = [...widget.category.units];

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _toggleUnit(int i) => setState(
    () => _units[i] = CategoryUnit(
      unit: _units[i].unit,
      hidden: !_units[i].hidden,
    ),
  );

  Future<void> _addUnit() async {
    final l10n = context.l10n;
    final unit = (await showTextPrompt(
      context,
      title: l10n.categoryUnits,
      hintText: l10n.priceUnitHint,
    ))?.trim();
    if (unit == null || unit.isEmpty || !mounted) return;
    setState(() {
      final at = _units.indexWhere((u) => u.unit == unit);
      // A unit typed again comes back instead of being added twice.
      if (at >= 0) {
        _units[at] = CategoryUnit(unit: unit);
      } else {
        _units.add(CategoryUnit(unit: unit));
      }
    });
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    await widget.cubit.save(
      ItemCategory(
        id: widget.category.id,
        name: name.isEmpty ? widget.category.name : name,
        sortOrder: widget.category.sortOrder,
        hidden: _hidden,
        units: _units,
      ),
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final t = context.tokens;
    final canEdit = widget.cubit.canEdit;
    return AppSheet(
      scrollController: widget.scrollController,
      title: widget.category.name,
      footer: canEdit
          ? FilledButton(
              onPressed: _save,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
              child: Text(l10n.save),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LabeledField(
            label: l10n.name,
            child: TextField(
              key: CategoriesUnitsPage.nameKey,
              controller: _name,
              enabled: canEdit,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(hintText: l10n.categoryNameHint),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.categoryHidden,
                  style: AppTextTheme.body.copyWith(
                    color: t.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Switch.adaptive(
                value: _hidden,
                onChanged: canEdit ? (v) => setState(() => _hidden = v) : null,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            l10n.categoryUnits,
            style: AppTextTheme.sectionTitle.copyWith(color: t.textPrimary),
          ),
          const SizedBox(height: 10),
          // Checked = offered as a chip in the item form; units are only
          // hidden, never removed (decision 25).
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final (i, unit) in _units.indexed)
                PickChip(
                  label: unit.unit,
                  selected: !unit.hidden,
                  onTap: canEdit ? () => _toggleUnit(i) : null,
                ),
              if (canEdit)
                PickChip(
                  label: '+ ${l10n.categoryUnits}',
                  selected: false,
                  onTap: _addUnit,
                ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
