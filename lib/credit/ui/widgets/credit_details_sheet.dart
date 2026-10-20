import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jabhouy/credit/logic/credit_money.dart';
import 'package:jabhouy/credit/models/credit.dart';
import 'package:jabhouy/credit/ui/bloc/credit_list/credit_list_cubit.dart';
import 'package:jabhouy_core/jabhouy_core.dart';
import 'package:jabhouy_l10n/jabhouy_l10n.dart';
import 'package:jabhouy_ui/jabhouy_ui.dart';

/// Opens [credit]'s details sheet (canvas ៨) with its lines. Needs a
/// [CreditListCubit] above [context]. [onEdit] adds the `កែ` button; the
/// form behind it is issue 30.
Future<void> showCreditDetails(
  BuildContext context,
  Credit credit, {
  ValueChanged<Credit>? onEdit,
}) async {
  final cubit = context.read<CreditListCubit>();
  final full = await cubit.credit(credit.id);
  if (full == null || !context.mounted) return;
  await showAppSheet<void>(
    context,
    builder: (sheetContext, controller) => CreditDetailsSheet(
      credit: full,
      canDelete: cubit.canDelete,
      scrollController: controller,
      onMarkPaid: () {
        Navigator.pop(sheetContext);
        cubit.markPaid(full.id);
      },
      onEdit: onEdit == null
          ? null
          : () {
              Navigator.pop(sheetContext);
              onEdit(full);
            },
      onDelete: () {
        Navigator.pop(sheetContext);
        cubit.delete(full.id);
      },
    ),
  );
}

/// A Credit at a glance: who, paid or not, how much, what was taken and
/// the note. Every Member marks paid and edits; only owner and editor
/// delete.
class CreditDetailsSheet extends StatelessWidget {
  const CreditDetailsSheet({
    required this.credit,
    required this.canDelete,
    required this.onMarkPaid,
    required this.onDelete,
    this.onEdit,
    this.scrollController,
    super.key,
  });

  final Credit credit;
  final bool canDelete;
  final VoidCallback onMarkPaid;

  /// Called once the user has confirmed.
  final VoidCallback onDelete;

  /// Null hides `កែ`.
  final VoidCallback? onEdit;
  final ScrollController? scrollController;

  Future<void> _confirmDelete(BuildContext context) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.confirmDelete),
        content: Text(l10n.confirmDeleteMessage(credit.customerName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              l10n.delete,
              style: TextStyle(color: context.tokens.dangerText),
            ),
          ),
        ],
      ),
    );
    if (confirmed ?? false) onDelete();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final t = context.tokens;
    final note = credit.note?.trim() ?? '';
    const buttonSize = Size.fromHeight(AppSizes.buttonHeight);
    final other = credit.currency == Currency.khr ? Currency.usd : Currency.khr;
    final amount = credit.amount;

    return AppSheet(
      scrollController: scrollController,
      header: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            credit.customerName,
            style: AppTextTheme.pageTitle.copyWith(color: t.textPrimary),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              StatusPill(paid: credit.isPaid),
              const SizedBox(width: 8),
              Text(
                l10n.formatDate(credit.takenAt.toPhnomPenh()),
                style: AppTextTheme.hint.copyWith(color: t.textMuted),
              ),
            ],
          ),
        ],
      ),
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!credit.isPaid) ...[
            FilledButton.icon(
              onPressed: onMarkPaid,
              style: FilledButton.styleFrom(
                minimumSize: buttonSize,
                shape: const StadiumBorder(),
              ),
              icon: const Icon(Icons.check_rounded, size: 18),
              label: Text(l10n.creditMarkPaid),
            ),
            if (onEdit != null || canDelete) const SizedBox(height: 12),
          ],
          if (onEdit != null || canDelete)
            Row(
              children: [
                if (onEdit != null)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onEdit,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        shape: const StadiumBorder(),
                        foregroundColor: t.textPrimary,
                      ),
                      child: Text(l10n.creditEditButton),
                    ),
                  ),
                if (onEdit != null && canDelete) const SizedBox(width: 12),
                if (canDelete)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _confirmDelete(context),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        shape: const StadiumBorder(),
                        foregroundColor: t.dangerText,
                        side: BorderSide(color: t.dangerBorder),
                      ),
                      child: Text(l10n.delete),
                    ),
                  ),
              ],
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: t.surfaceSubtle,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Expanded(
                  child: Text(
                    l10n.creditAmountDue,
                    style: AppTextTheme.label.copyWith(
                      color: t.textSecondary,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
                if (amount == null)
                  Text(
                    l10n.creditNoAmount,
                    style: AppTextTheme.label.copyWith(
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
                        style: AppTextTheme.headline.copyWith(
                          color: t.textPrimary,
                          fontSize: 26,
                        ),
                      ),
                      Text(
                        amountIn(credit, other)!.formatApprox(),
                        style: AppTextTheme.hint.copyWith(color: t.textMuted),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          if (credit.lines.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              l10n.creditItems,
              style: AppTextTheme.hint.copyWith(
                color: t.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            for (final line in credit.lines)
              _LineRow(line: line, credit: credit),
          ],
          if (note.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              l10n.noteLabel,
              style: AppTextTheme.hint.copyWith(
                color: t.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              note,
              style: AppTextTheme.body.copyWith(color: t.textPrimary),
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

/// `ទឹក` with `2 ដប · 3,000 ៛` below and the line's total in the Credit's
/// currency on the right.
class _LineRow extends StatelessWidget {
  const _LineRow({required this.line, required this.credit});

  final CreditLine line;
  final Credit credit;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  line.name,
                  style: AppTextTheme.body.copyWith(color: t.textPrimary),
                ),
                Text(
                  '${line.qty} ${line.unit} · '
                  '${Money(line.unitPrice, line.currency).format()}',
                  style: AppTextTheme.hint.copyWith(color: t.textMuted),
                ),
              ],
            ),
          ),
          Text(
            lineIn(line, credit.currency, credit.khrPerUsd).format(),
            style: AppTextTheme.body.copyWith(
              color: t.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
