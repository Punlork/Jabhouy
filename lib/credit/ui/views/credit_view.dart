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
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FilterChips(
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
            ClipRect(
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                alignment: Alignment.topCenter,
                heightFactor: widget.chromeVisible ? 1 : 0,
                child: summary == null
                    ? const SizedBox(width: double.infinity)
                    : Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
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
                    const SizedBox(height: 8),
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
                    else
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: context.tokens.surface,
                            borderRadius: BorderRadius.circular(
                              AppSizes.radiusCard,
                            ),
                          ),
                          child: Column(
                            children: [
                              for (final (i, credit) in state.credits.indexed)
                                _CreditRow(
                                  credit: credit,
                                  divider: i < state.credits.length - 1,
                                  onTap: widget.onOpen == null
                                      ? null
                                      : () => widget.onOpen!(credit),
                                ),
                            ],
                          ),
                        ),
                      ),
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

/// The dark card: what is owed, in both currencies, and by how many.
class _SummaryCard extends StatelessWidget {
  const _SummaryCard(this.summary);

  final CreditSummary summary;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l10n = context.l10n;
    final soft = t.surface.withValues(alpha: 0.8);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: t.textPrimary,
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.creditTotalOwed,
            style: AppTextTheme.hint.copyWith(color: soft),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                summary.total.format(),
                style: AppTextTheme.headline.copyWith(
                  color: t.surface,
                  fontSize: 28,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                summary.other.formatApprox(),
                style: AppTextTheme.label.copyWith(
                  color: soft,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
          Text(
            [
              l10n.creditSummaryPeople(summary.people),
              if (summary.peopleWithoutAmount > 0)
                l10n.creditSummaryUnknown(summary.peopleWithoutAmount),
            ].join(' · '),
            style: AppTextTheme.hint.copyWith(color: soft, fontSize: 13),
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
                  child: Text(
                    note,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextTheme.hint.copyWith(color: t.textMuted),
                  ),
                ),
                const SizedBox(width: 8),
                StatusPill(paid: credit.isPaid),
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
