import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jabhouy/credit/logic/credit_money.dart';
import 'package:jabhouy/credit/models/credit.dart';
import 'package:jabhouy/credit/ui/bloc/credit_list/credit_list_cubit.dart';
import 'package:jabhouy_core/jabhouy_core.dart';
import 'package:jabhouy_l10n/jabhouy_l10n.dart';
import 'package:jabhouy_ui/jabhouy_ui.dart';

/// The Credit tab (canvas ៧): the summary card, the chips, and one row per
/// Credit; Home's header carries the customer search. A tap calls [onOpen]; the details sheet
/// (issue 28) is what opens. The chips stay pinned like the shop's; the
/// summary card follows Home's header away while scrolling down.
class CreditView extends StatefulWidget {
  const CreditView({this.onOpen, this.chromeVisible = true, super.key});

  final ValueChanged<Credit>? onOpen;

  /// False while Home scrolls its search row away; the summary follows it.
  final bool chromeVisible;

  @override
  State<CreditView> createState() => _CreditViewState();
}

class _CreditViewState extends State<CreditView>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = context.l10n;
    final cubit = context.read<CreditListCubit>();
    // The Credit tab owns slot 1 in Home's TabScrollManager.
    final controller = TabScrollManager.of(context)?.getController(1);

    return BlocBuilder<CreditListCubit, CreditListState>(
      builder: (context, state) {
        final summary = state.summary;
        final grouped =
            !state.loading &&
            state.credits.isNotEmpty &&
            state.sort == CreditSort.recent;
        final sortMenu = SortMenu<CreditSort>(
          tooltip: l10n.itemSortTooltip,
          options: [
            (
              CreditSort.name,
              Icons.sort_by_alpha_rounded,
              l10n.itemSortName,
              l10n.itemSortNameReversed,
            ),
            (
              CreditSort.recent,
              Icons.schedule_rounded,
              l10n.itemSortRecent,
              l10n.itemSortRecentReversed,
            ),
          ],
          selected: state.sort,
          reversed: state.sortReversed,
          onChanged: cubit.setSort,
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Once the search row scrolls away, the chips would touch the
            // status bar above and the list below.
            AnimatedPadding(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              padding: EdgeInsets.symmetric(
                vertical: widget.chromeVisible ? 0 : 8,
              ),
              child: FilterChips(
                items: [
                  FilterChipItem(
                    label: l10n.creditUnpaid,
                    selected: state.filter == CreditFilter.unpaid,
                    onTap: () => cubit.filter(CreditFilter.unpaid),
                  ),
                  FilterChipItem(
                    label: l10n.creditPaid,
                    selected: state.filter == CreditFilter.paid,
                    onTap: () => cubit.filter(CreditFilter.paid),
                  ),
                  FilterChipItem(
                    label: l10n.all,
                    selected: state.filter == CreditFilter.all,
                    onTap: () => cubit.filter(CreditFilter.all),
                  ),
                ],
              ),
            ),
            ClipRect(
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                alignment: Alignment.topCenter,
                heightFactor: widget.chromeVisible ? 1 : 0,
                child: summary == null
                    ? const SizedBox(width: double.infinity)
                    : Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                        child: _SummaryCard(summary),
                      ),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: cubit.refresh,
                child: ListView(
                  controller: controller,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  children: [
                    // Grouped by day, the sort icon rides on the first heading;
                    // otherwise it gets a row of its own.
                    if (!grouped)
                      Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: sortMenu,
                        ),
                      ),
                    if (state.loading)
                      const Padding(
                        padding: EdgeInsets.only(top: 80),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (state.credits.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 80),
                        child: Center(
                          child: Text(
                            l10n.creditListEmpty,
                            style: AppTextTheme.body.copyWith(
                              color: context.tokens.textMuted,
                            ),
                          ),
                        ),
                      )
                    else if (state.sort == CreditSort.name)
                      // Sorted by name, days would be out of order: one list.
                      _CreditGroup(
                        credits: state.credits,
                        onOpen: widget.onOpen,
                      )
                    else
                      for (final (i, group) in _groupByDay(
                        state.credits,
                      ).indexed) ...[
                        _DayHeading(
                          group.day,
                          trailing: i == 0 ? sortMenu : null,
                        ),
                        _CreditGroup(
                          credits: group.credits,
                          onOpen: widget.onOpen,
                        ),
                      ],
                    // Room for the nav bar and its floating button.
                    const SizedBox(height: 160),
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

/// Credits taken on one Phnom Penh calendar day.
typedef _DayGroup = ({DateTime day, List<Credit> credits});

DateTime _phnomPenhDay(DateTime moment) {
  final wall = moment.toPhnomPenh();
  return DateTime.utc(wall.year, wall.month, wall.day);
}

/// Runs of [credits] (already sorted by time) that share a day, in order.
List<_DayGroup> _groupByDay(List<Credit> credits) {
  final groups = <_DayGroup>[];
  for (final credit in credits) {
    final day = _phnomPenhDay(credit.takenAt);
    if (groups.isNotEmpty && groups.last.day == day) {
      groups.last.credits.add(credit);
    } else {
      groups.add((day: day, credits: [credit]));
    }
  }
  return groups;
}

/// `Today`, `Yesterday`, or the date, with an optional control at the end.
class _DayHeading extends StatelessWidget {
  const _DayHeading(this.day, {this.trailing});

  final DateTime day;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final today = _phnomPenhDay(DateTime.now());
    final label = switch (today.difference(day).inDays) {
      <= 0 => l10n.creditGroupToday,
      1 => l10n.creditGroupYesterday,
      _ => l10n.formatDate(day),
    };
    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(
        20,
        trailing == null ? 10 : 0,
        trailing == null ? 20 : 8,
        4,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTextTheme.label.copyWith(
                color: context.tokens.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// One white card holding a run of Credit rows.
class _CreditGroup extends StatelessWidget {
  const _CreditGroup({required this.credits, required this.onOpen});

  final List<Credit> credits;
  final ValueChanged<Credit>? onOpen;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: context.tokens.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        ),
        child: Column(
          children: [
            for (final (i, credit) in credits.indexed)
              _CreditRow(
                credit: credit,
                divider: i < credits.length - 1,
                onTap: onOpen == null ? null : () => onOpen!(credit),
              ),
          ],
        ),
      ),
    );
  }
}

/// The minimal card: what is owed in both currencies, and by how many.
class _SummaryCard extends StatelessWidget {
  const _SummaryCard(this.summary);

  final CreditSummary summary;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l10n = context.l10n;
    final hint = AppTextTheme.hint.copyWith(color: t.textMuted, fontSize: 13);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: t.dividerStrong),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.end,
            spacing: 8,
            children: [
              Text(l10n.creditTotalOwed, style: hint.copyWith(fontSize: 14)),
              Text(
                summary.total.format(),
                style: AppTextTheme.headline.copyWith(
                  color: t.textPrimary,
                  fontSize: 20,
                ),
              ),
              Text(
                summary.other.formatApprox(),
                style: hint.copyWith(fontSize: 14),
              ),
            ],
          ),
          Text.rich(
            TextSpan(
              style: hint,
              children: [
                TextSpan(text: l10n.creditSummaryPeople(summary.people)),
                if (summary.peopleWithoutAmount > 0) ...[
                  const TextSpan(text: ' · '),
                  TextSpan(
                    text: l10n.creditSummaryUnknown(
                      summary.peopleWithoutAmount,
                    ),
                    style: TextStyle(
                      color: t.warningText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CreditRow extends StatelessWidget {
  const _CreditRow({
    required this.credit,
    required this.divider,
    required this.onTap,
  });

  final Credit credit;
  final bool divider;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l10n = context.l10n;
    final amount = credit.amount;
    final other = credit.currency == Currency.khr ? Currency.usd : Currency.khr;
    final note = credit.note?.trim() ?? '';
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: divider ? Border(bottom: BorderSide(color: t.divider)) : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    credit.customerName,
                    style: AppTextTheme.body.copyWith(
                      color: t.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (amount == null)
                  Text(
                    l10n.creditNoAmount,
                    style: AppTextTheme.hint.copyWith(
                      color: t.warningText,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        Money(amount, credit.currency).format(),
                        style: AppTextTheme.title.copyWith(
                          color: t.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        amountIn(credit, other)!.formatApprox(),
                        style: AppTextTheme.hint.copyWith(
                          color: t.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  // Read often: body size, darker, and the whole note.
                  child: Text(
                    note,
                    style: AppTextTheme.body.copyWith(
                      color: t.textSecondary,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${l10n.formatDate(credit.takenAt.toPhnomPenh())}'
              ' ${l10n.formatTime(credit.takenAt.toPhnomPenh())}',
              style: AppTextTheme.hint.copyWith(
                color: t.textMuted,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
