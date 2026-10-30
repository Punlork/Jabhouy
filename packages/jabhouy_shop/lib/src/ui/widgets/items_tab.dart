import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:jabhouy_l10n/jabhouy_l10n.dart';
import 'package:jabhouy_shop/src/logic/item_search.dart';
import 'package:jabhouy_shop/src/models/item.dart';
import 'package:jabhouy_shop/src/ui/bloc/item_list/item_list_cubit.dart';
import 'package:jabhouy_shop/src/ui/widgets/item_details_sheet.dart';
import 'package:jabhouy_ui/jabhouy_ui.dart';

/// Home's shop tab (canvas ១, ១ក): filter chips, recently viewed pills,
/// the list header with the grid toggle, and every Item with one line per
/// Price option. A tap opens the details sheet; its `កែតម្លៃ` calls
/// [onEditItem]. While searching, the pills give way to `លទ្ធផល n` and the
/// results come as a list, ending in a card whose button calls [onAddItem]
/// with the query.
class ItemsTab extends StatefulWidget {
  const ItemsTab({
    required this.onEditItem,
    required this.onAddItem,
    this.chromeVisible = true,
    super.key,
  });

  final ValueChanged<Item> onEditItem;
  final ValueChanged<String> onAddItem;

  /// False while Home scrolls its search row away: the pills and list
  /// header follow it, the chips stay (decision 43).
  final bool chromeVisible;

  @override
  State<ItemsTab> createState() => _ItemsTabState();
}

class _ItemsTabState extends State<ItemsTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  Future<void> _openItem(Item item) =>
      showItemDetails(context, item, onEdit: widget.onEditItem);

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
        final query = state.query.trim();
        final searching = normalizeSearch(query).isNotEmpty;
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
            ClipRect(
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                alignment: Alignment.topCenter,
                heightFactor: widget.chromeVisible ? 1 : 0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (!searching && state.recent.isNotEmpty)
                      _RecentPills(items: state.recent, onTap: _openItem),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 4, 8, 0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              searching
                                  ? l10n.itemSearchResults(state.items.length)
                                  : l10n.itemListHeader(state.items.length),
                              style: AppTextTheme.hint.copyWith(
                                color: t.textSecondary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          SortButtons<ItemSort>(
                            options: [
                              (
                                ItemSort.name,
                                state.sort == ItemSort.name &&
                                        state.sortReversed
                                    ? l10n.itemSortNameReversed
                                    : l10n.itemSortName,
                              ),
                              (
                                ItemSort.recent,
                                state.sort == ItemSort.recent &&
                                        state.sortReversed
                                    ? l10n.itemSortRecentReversed
                                    : l10n.itemSortRecent,
                              ),
                            ],
                            selected: state.sort,
                            reversed: state.sortReversed,
                            onChanged: cubit.setSort,
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
                  ],
                ),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: cubit.refresh,
                child: state.loading
                    ? const Center(child: CircularProgressIndicator())
                    : state.items.isEmpty
                    // A scroll view, so an empty list can still be pulled.
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: _listPadding,
                        children: [
                          if (searching && state.canEdit)
                            _NotFoundCard(
                              query: query,
                              onAdd: () => widget.onAddItem(query),
                            )
                          else ...[
                            const SizedBox(height: 160),
                            Center(
                              child: Text(
                                l10n.itemListEmpty,
                                style: AppTextTheme.body.copyWith(
                                  color: t.textMuted,
                                ),
                              ),
                            ),
                          ],
                        ],
                      )
                    // Results are few, and the not-found card needs full width.
                    : state.grid && !searching
                    ? MasonryGridView.count(
                        controller: controller,
                        physics: const AlwaysScrollableScrollPhysics(),
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
                        physics: const AlwaysScrollableScrollPhysics(),
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
                                    matchedNickname:
                                        state.nicknameMatches[item.id],
                                    query: query,
                                    onTap: () => _openItem(item),
                                  ),
                              ],
                            ),
                          ),
                          if (searching && state.canEdit)
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: _NotFoundCard(
                                query: query,
                                onAdd: () => widget.onAddItem(query),
                              ),
                            ),
                        ],
                      ),
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
    this.matchedNickname,
    this.query = '',
  });

  final Item item;
  final bool divider;
  final String? matchedNickname;
  final String query;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          border: divider ? Border(bottom: BorderSide(color: t.divider)) : null,
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
                  if (matchedNickname case final nickname?)
                    _NicknameLine(nickname: nickname, query: query),
                  if (item.prices.isEmpty)
                    const _PriceLine(null)
                  else
                    ..._priceLines(context, item),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// `ឈ្មោះផ្សេង៖ ទឹកធំ` with the typed part in bold.
class _NicknameLine extends StatelessWidget {
  const _NicknameLine({required this.nickname, required this.query});

  final String nickname;
  final String query;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final style = AppTextTheme.hint.copyWith(color: t.textMuted);
    final q = normalizeSearch(query);
    // A fuzzy match has no exact stretch to bold.
    final at = nickname.toLowerCase().indexOf(q);
    final end = at + q.length;
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Text.rich(
        TextSpan(
          style: style,
          children: [
            TextSpan(text: '${context.l10n.itemOtherName} '),
            if (at < 0)
              TextSpan(text: nickname)
            else ...[
              TextSpan(text: nickname.substring(0, at)),
              TextSpan(
                text: nickname.substring(at, end),
                style: TextStyle(
                  color: t.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              TextSpan(text: nickname.substring(end)),
            ],
          ],
        ),
      ),
    );
  }
}

/// Canvas ១ក: recently viewed Items, one tap from their details.
class _RecentPills extends StatelessWidget {
  const _RecentPills({required this.items, required this.onTap});

  final List<Item> items;
  final ValueChanged<Item> onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return SizedBox(
      height: 56,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final item = items[i];
          final price = item.prices.firstOrNull?.selling?.format();
          return Semantics(
            label: context.l10n.itemRecentLabel,
            child: Material(
              color: t.surface,
              shape: StadiumBorder(side: BorderSide(color: t.divider)),
              child: InkWell(
                customBorder: const StadiumBorder(),
                onTap: () => onTap(item),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      Icon(Icons.schedule, size: 14, color: t.textMuted),
                      const SizedBox(width: 6),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 84),
                        child: Text(
                          item.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextTheme.hint.copyWith(
                            color: t.textPrimary,
                          ),
                        ),
                      ),
                      if (price != null) ...[
                        const SizedBox(width: 6),
                        Text(
                          price,
                          style: AppTextTheme.hint.copyWith(
                            color: t.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Under the results: not what you meant? Add it with the typed name.
class _NotFoundCard extends StatelessWidget {
  const _NotFoundCard({required this.query, required this.onAdd});

  final String query;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        border: Border.all(color: t.divider),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.l10n.itemNotFound,
              textAlign: TextAlign.center,
              style: AppTextTheme.body.copyWith(color: t.textSecondary),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: onAdd,
              child: Text(
                context.l10n.itemAddNamed(query),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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
              if (item.prices.isEmpty)
                const _PriceLine(null)
              else
                ..._priceLines(context, item),
            ],
          ),
        ),
      ),
    );
  }
}

/// Three price lines at most, then `+n ទៀត`: the sheet shows the rest.
List<Widget> _priceLines(BuildContext context, Item item) {
  const shown = 3;
  return [
    for (final option in item.prices.take(shown)) _PriceLine(option),
    if (item.prices.length > shown)
      Padding(
        padding: const EdgeInsets.only(top: 3),
        child: Text(
          context.l10n.itemMorePrices(item.prices.length - shown),
          style: AppTextTheme.hint.copyWith(color: context.tokens.textMuted),
        ),
      ),
  ];
}

/// `ដប` or `កេះ (12)` on the left, the price on the right. A null
/// [option] is an Item saved without prices: `មិនទាន់មានតម្លៃ` alone.
class _PriceLine extends StatelessWidget {
  const _PriceLine(this.option);

  final PriceOption? option;

  @override
  Widget build(BuildContext context) {
    final option = this.option;
    if (option == null) {
      return const Padding(
        padding: EdgeInsets.only(top: 3),
        child: Align(
          alignment: AlignmentDirectional.centerEnd,
          child: PriceDisplay(price: null, khrPerUsd: 0, showConverted: false),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Expanded(
            child: Text(
              option.label,
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

/// Shows [item]'s details sheet (canvas ២) and records it as viewed.
/// Needs an [ItemListCubit] above [context]; Home's scan uses it too.
Future<void> showItemDetails(
  BuildContext context,
  Item item, {
  required ValueChanged<Item> onEdit,
}) async {
  final cubit = context.read<ItemListCubit>();
  unawaited(cubit.viewed(item.id));
  final editorName = await cubit.editorName(item.updatedBy);
  if (!context.mounted) return;
  final state = cubit.state;
  final category = state.categories.where((c) => c.id == item.categoryId);
  await showAppSheet<void>(
    context,
    initialSize: 0.55,
    builder: (sheetContext, controller) => ItemDetailsSheet(
      scrollController: controller,
      item: item,
      categoryName: category.isEmpty ? null : category.first.name,
      settings: state.settings,
      canEdit: state.canEdit,
      editorName: editorName,
      onEdit: () {
        Navigator.pop(sheetContext);
        onEdit(item);
      },
      onDelete: () {
        Navigator.pop(sheetContext);
        cubit.delete(item.id);
      },
    ),
  );
}
