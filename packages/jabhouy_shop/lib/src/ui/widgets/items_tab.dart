import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:jabhouy_l10n/jabhouy_l10n.dart';
import 'package:jabhouy_shop/src/models/item.dart';
import 'package:jabhouy_shop/src/ui/bloc/item_list/item_list_cubit.dart';
import 'package:jabhouy_shop/src/ui/widgets/item_details_sheet.dart';
import 'package:jabhouy_ui/jabhouy_ui.dart';

/// Home's shop tab (canvas ១, ១ក): filter chips, the list header with the
/// grid toggle, and every Item with one line per Price option. A tap
/// opens the details sheet; its `កែតម្លៃ` calls [onEditItem].
class ItemsTab extends StatefulWidget {
  const ItemsTab({required this.onEditItem, super.key});

  final ValueChanged<Item> onEditItem;

  @override
  State<ItemsTab> createState() => _ItemsTabState();
}

class _ItemsTabState extends State<ItemsTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  Future<void> _openItem(Item item) async {
    final cubit = context.read<ItemListCubit>();
    final editorName = await cubit.editorName(item.updatedBy);
    if (!mounted) return;
    final state = cubit.state;
    final category = state.categories.where((c) => c.id == item.categoryId);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => ItemDetailsSheet(
        item: item,
        categoryName: category.isEmpty ? null : category.first.name,
        settings: state.settings,
        canEdit: state.canEdit,
        editorName: editorName,
        onEdit: () {
          Navigator.pop(sheetContext);
          widget.onEditItem(item);
        },
        onDelete: () {
          Navigator.pop(sheetContext);
          cubit.delete(item.id);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = context.l10n;
    final t = context.tokens;
    final cubit = context.read<ItemListCubit>();
    // The shop tab owns slot 0 in Home's TabScrollManager.
    final controller = TabScrollManager.of(context)?.getController(0);

    return BlocBuilder<ItemListCubit, ItemListState>(
      builder: (context, state) {
        final all = state.categoryId == null && !state.missingOnly;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FilterChips(
              items: [
                FilterChipItem(
                  label: l10n.all,
                  selected: all,
                  onTap: cubit.filter,
                ),
                if (state.canEdit && state.missingCount > 0)
                  FilterChipItem(
                    label: l10n.priceMissing,
                    selected: state.missingOnly,
                    warningCount: state.missingCount,
                    onTap: () => cubit.filter(missingOnly: true),
                  ),
                for (final category in state.categories)
                  if (!category.hidden)
                    FilterChipItem(
                      label: category.name,
                      selected: category.id == state.categoryId,
                      onTap: () => cubit.filter(categoryId: category.id),
                    ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 8, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.itemListHeader(state.items.length),
                      style: AppTextTheme.hint.copyWith(
                        color: t.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: cubit.toggleGrid,
                    tooltip: state.grid
                        ? l10n.itemListShowList
                        : l10n.itemListShowGrid,
                    icon: Icon(
                      state.grid
                          ? Icons.view_agenda_outlined
                          : Icons.grid_view_rounded,
                      color: t.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: state.loading
                  ? const Center(child: CircularProgressIndicator())
                  : state.items.isEmpty
                  ? Center(
                      child: Text(
                        l10n.itemListEmpty,
                        style: AppTextTheme.body.copyWith(color: t.textMuted),
                      ),
                    )
                  : state.grid
                  ? MasonryGridView.count(
                      controller: controller,
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      padding: _listPadding,
                      itemCount: state.items.length,
                      itemBuilder: (context, i) => _ItemCard(
                        item: state.items[i],
                        onTap: () => _openItem(state.items[i]),
                      ),
                    )
                  : ListView(
                      controller: controller,
                      padding: _listPadding,
                      children: [
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: t.surface,
                            borderRadius: BorderRadius.circular(
                              AppSizes.radiusCard,
                            ),
                          ),
                          child: Column(
                            children: [
                              for (final (i, item) in state.items.indexed)
                                _ItemRow(
                                  item: item,
                                  divider: i < state.items.length - 1,
                                  onTap: () => _openItem(item),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        );
      },
    );
  }
}

/// Room at the bottom for the nav bar and its floating button.
const _listPadding = EdgeInsets.fromLTRB(16, 4, 16, 160);

class _ItemRow extends StatelessWidget {
  const _ItemRow({
    required this.item,
    required this.divider,
    required this.onTap,
  });

  final Item item;
  final bool divider;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          border: divider
              ? Border(bottom: BorderSide(color: t.divider))
              : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Thumbnail(item.name),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    item.name,
                    style: AppTextTheme.body.copyWith(
                      color: t.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  for (final option in item.prices) _PriceLine(option),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemCard extends StatelessWidget {
  const _ItemCard({required this.item, required this.onTap});

  final Item item;
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
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Thumbnail(item.name),
              const SizedBox(height: 8),
              Text(
                item.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextTheme.body.copyWith(
                  color: t.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              for (final option in item.prices) _PriceLine(option),
            ],
          ),
        ),
      ),
    );
  }
}

/// `1 ដប` or `1 កេះ · ×24` on the left, the price on the right.
class _PriceLine extends StatelessWidget {
  const _PriceLine(this.option);

  final PriceOption option;

  @override
  Widget build(BuildContext context) {
    final pack = option.packQty == null ? '' : ' · ×${option.packQty}';
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Expanded(
            child: Text(
              '1 ${option.unit}$pack',
              style: AppTextTheme.hint.copyWith(
                color: context.tokens.textMuted,
              ),
            ),
          ),
          PriceDisplay(
            price: option.selling,
            // Unused: Home shows no converted line (plan §5.1).
            khrPerUsd: 0,
            showConverted: false,
          ),
        ],
      ),
    );
  }
}

/// First letter of the name; photos come with issue 24.
class _Thumbnail extends StatelessWidget {
  const _Thumbnail(this.name);

  final String name;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final letter = name.isEmpty ? '' : String.fromCharCode(name.runes.first);
    return Container(
      width: AppSizes.minTapTarget,
      height: AppSizes.minTapTarget,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: t.surfaceMuted,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        letter,
        style: AppTextTheme.sectionTitle.copyWith(color: t.textMuted),
      ),
    );
  }
}
