import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jabhouy/credit/logic/credit_money.dart';
import 'package:jabhouy/credit/models/credit.dart';
import 'package:jabhouy/credit/ui/bloc/item_picker/item_picker_cubit.dart';
import 'package:jabhouy_core/jabhouy_core.dart';
import 'package:jabhouy_l10n/jabhouy_l10n.dart';
import 'package:jabhouy_shop/jabhouy_shop.dart';
import 'package:jabhouy_ui/jabhouy_ui.dart';

/// The item picker (canvas ៩ក): search, category chips, every Price option
/// of every Item as its own row with a `+` that becomes a stepper, and a
/// footer with the running total in the Credit's [currency] at its
/// [khrPerUsd]. Returns the Credit's whole set of lines, or null when
/// dismissed. [initial] are the lines already on the Credit.
Future<List<CreditLine>?> showItemPicker(
  BuildContext context,
  ItemRepository items, {
  required Currency currency,
  required int khrPerUsd,
  List<CreditLine> initial = const [],
}) => showAppSheet<List<CreditLine>>(
  context,
  initialSize: 0.92,
  builder: (_, controller) => BlocProvider(
    create: (_) => ItemPickerCubit(items, initial: initial)..start(),
    child: _ItemPickerSheet(
      currency: currency,
      khrPerUsd: khrPerUsd,
      scrollController: controller,
    ),
  ),
);

class _ItemPickerSheet extends StatelessWidget {
  const _ItemPickerSheet({
    required this.currency,
    required this.khrPerUsd,
    this.scrollController,
  });

  final Currency currency;
  final int khrPerUsd;
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final t = context.tokens;
    final cubit = context.read<ItemPickerCubit>();
    final other = currency == Currency.khr ? Currency.usd : Currency.khr;

    return BlocBuilder<ItemPickerCubit, ItemPickerState>(
      builder: (context, state) {
        final total = sumOfLines(state.lines, currency, khrPerUsd);
        return AppSheet(
          scrollController: scrollController,
          title: l10n.pickerTitle,
          pinned: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.screenPadding,
                ),
                child: MicSearchField(
                  hintText: l10n.searchGoods,
                  onChanged: cubit.search,
                ),
              ),
              const SizedBox(height: 4),
              FilterChips(
                items: [
                  FilterChipItem(
                    label: l10n.all,
                    selected: state.categoryId == null,
                    onTap: () => cubit.selectCategory(null),
                  ),
                  for (final c in state.categories)
                    if (!c.hidden)
                      FilterChipItem(
                        label: c.name,
                        selected: c.id == state.categoryId,
                        onTap: () => cubit.selectCategory(c.id),
                      ),
                ],
              ),
            ],
          ),
          footer: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Expanded(
                    child: Text(
                      l10n.pickerSelected(state.lines.length),
                      style: AppTextTheme.hint.copyWith(color: t.textMuted),
                    ),
                  ),
                  if (total != null) ...[
                    Text(
                      total
                          .convertTo(other, khrPerUsd: khrPerUsd)
                          .formatApprox(),
                      style: AppTextTheme.hint.copyWith(color: t.textMuted),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      total.format(),
                      style: AppTextTheme.title.copyWith(
                        color: t.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 10),
              FilledButton(
                onPressed: state.lines.isEmpty
                    ? null
                    : () => Navigator.pop(context, state.lines),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(AppSizes.buttonHeight),
                  shape: const StadiumBorder(),
                ),
                child: Text(l10n.pickerAddToCredit),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (state.loading)
                const Padding(
                  padding: EdgeInsets.only(top: 40),
                  child: Center(child: CircularProgressIndicator()),
                )
              else
                for (final (i, item) in state.items.indexed)
                  _ItemBlock(
                    item: item,
                    quantities: state.quantities,
                    divider: i < state.items.length - 1,
                    onQty: cubit.setQty,
                  ),
            ],
          ),
        );
      },
    );
  }
}

class _ItemBlock extends StatelessWidget {
  const _ItemBlock({
    required this.item,
    required this.quantities,
    required this.divider,
    required this.onQty,
  });

  final Item item;
  final Map<String, int> quantities;
  final bool divider;
  final void Function(String priceId, int qty) onQty;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: divider ? Border(bottom: BorderSide(color: t.divider)) : null,
      ),
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
          const SizedBox(height: 4),
          for (final option in item.prices)
            _OptionRow(
              option: option,
              qty: quantities[option.id] ?? 0,
              onQty: (qty) => onQty(option.id, qty),
            ),
        ],
      ),
    );
  }
}

/// `1 ដប · 3,000 ៛` and its `+`; a highlighted stepper once chosen. An
/// option with no price yet cannot be taken.
class _OptionRow extends StatelessWidget {
  const _OptionRow({
    required this.option,
    required this.qty,
    required this.onQty,
  });

  final PriceOption option;
  final int qty;
  final ValueChanged<int> onQty;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final price = option.selling;
    // The highlight bleeds 8 px past the text, as drawn, so it is a layer
    // behind the row rather than the row's own padding.
    return Stack(
      clipBehavior: Clip.none,
      children: [
        if (qty > 0)
          Positioned(
            left: -8,
            right: -8,
            top: 0,
            bottom: 0,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: t.surfaceSubtle,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '1 ${option.label}',
                  style: AppTextTheme.hint.copyWith(color: t.textSecondary),
                ),
              ),
              if (price == null)
                Text(
                  context.l10n.priceMissing,
                  style: AppTextTheme.hint.copyWith(
                    color: t.warningText,
                    fontWeight: FontWeight.w600,
                  ),
                )
              else ...[
                Text(
                  price.format(),
                  style: AppTextTheme.body.copyWith(
                    color: t.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 10),
                if (qty > 0)
                  QtyStepper(value: qty, onChanged: onQty)
                else
                  SizedBox(
                    width: 44,
                    height: 40,
                    child: OutlinedButton(
                      onPressed: () => onQty(1),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        foregroundColor: t.textPrimary,
                        side: BorderSide(color: t.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Icon(Icons.add_rounded, size: 20),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
