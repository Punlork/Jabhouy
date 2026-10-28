import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jabhouy/credit/models/credit.dart';
import 'package:jabhouy/credit/ui/bloc/credit_form/credit_form_cubit.dart';
import 'package:jabhouy_core/jabhouy_core.dart';
import 'package:jabhouy_l10n/jabhouy_l10n.dart';
import 'package:jabhouy_shop/jabhouy_shop.dart' show ErrorLine;
import 'package:jabhouy_ui/jabhouy_ui.dart';

/// Opens the customer picker; null when dismissed.
typedef PickCustomer =
    Future<CreditCustomer?> Function(BuildContext context, String? selectedId);

/// Opens the item picker with the Credit's lines; null when dismissed.
typedef PickItems =
    Future<List<CreditLine>?> Function(
      BuildContext context, {
      required Currency currency,
      required int khrPerUsd,
      required List<CreditLine> initial,
    });

/// Add or edit a Credit (canvas ៩, ៩ខ, ១០). Expects a [CreditFormCubit]
/// above it; edits when the cubit has `existing`. The pickers come in as
/// functions so the page never reaches for the app's service locator.
class CreditFormPage extends StatefulWidget {
  const CreditFormPage({
    required this.pickCustomer,
    required this.pickItems,
    super.key,
  });

  final PickCustomer pickCustomer;
  final PickItems pickItems;

  @override
  State<CreditFormPage> createState() => _CreditFormPageState();
}

class _CreditFormPageState extends State<CreditFormPage> {
  late final _cubit = context.read<CreditFormCubit>();
  late final _note = TextEditingController(text: _cubit.existing?.note);

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _chooseCustomer() async {
    final picked = await widget.pickCustomer(
      context,
      _cubit.state.customer?.id,
    );
    if (picked != null) _cubit.setCustomer(picked);
  }

  Future<void> _addItems() async {
    final state = _cubit.state;
    final lines = await widget.pickItems(
      context,
      currency: state.currency,
      khrPerUsd: state.khrPerUsd,
      initial: state.lines,
    );
    if (lines != null) _cubit.setLines(lines);
  }

  Future<void> _pickDue(CreditFormState state) async {
    final wall = state.takenAt.toPhnomPenh();
    final picked = await showDatePicker(
      context: context,
      initialDate: state.dueDate ?? DateTime(wall.year, wall.month, wall.day),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) _cubit.setDueDate(picked);
  }

  /// Wall-clock time in Phnom Penh back to the UTC moment it stores.
  static DateTime _utc(int y, int m, int d, int h, int min) =>
      DateTime.utc(y, m, d, h, min).subtract(const Duration(hours: 7));

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final t = context.tokens;
    return BlocConsumer<CreditFormCubit, CreditFormState>(
      listenWhen: (a, b) => a.status != b.status || a.error != b.error,
      listener: (context, state) {
        if (state.status == CreditFormStatus.saved) {
          Navigator.of(context).maybePop();
        }
        if (state.error case final error?) showErrorSnackBar(context, error);
      },
      builder: (context, state) {
        final loading = state.status == CreditFormStatus.loading;
        return Scaffold(
          backgroundColor: t.bg,
          appBar: AppBar(
            centerTitle: false,
            leading: IconButton(
              onPressed: () => Navigator.of(context).maybePop(),
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            title: Text(
              _cubit.existing == null ? l10n.creditAdd : l10n.creditEdit,
            ),
          ),
          body: loading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  children: [
                    _customer(state),
                    const SizedBox(height: AppSizes.sectionGap),
                    _lines(state),
                    const SizedBox(height: AppSizes.sectionGap),
                    _amount(state),
                    const SizedBox(height: AppSizes.sectionGap),
                    _takenAt(state),
                    const SizedBox(height: AppSizes.sectionGap),
                    LabeledField(
                      label: l10n.creditDueDate,
                      optional: true,
                      child: _DueDateField(
                        day: state.dueDate,
                        onTap: () => _pickDue(state),
                        onClear: () => _cubit.setDueDate(null),
                      ),
                    ),
                    const SizedBox(height: AppSizes.sectionGap),
                    LabeledField(
                      label: l10n.statusLabel,
                      child: SegmentedControl<CreditStatus>(
                        options: [
                          (CreditStatus.unpaid, l10n.creditUnpaid),
                          (CreditStatus.paid, l10n.creditPaid),
                        ],
                        selected: state.creditStatus,
                        onChanged: _cubit.setStatus,
                      ),
                    ),
                    const SizedBox(height: AppSizes.sectionGap),
                    LabeledField(
                      label: l10n.noteLabel,
                      optional: true,
                      child: TextField(
                        controller: _note,
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText: l10n.creditNoteHint,
                          suffixIcon: MicButton(
                            fieldLabel: l10n.noteLabel,
                            onText: (text) => _note.text = text,
                          ),
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
                  // Never disabled: a missing customer shows on save.
                  onPressed: loading ? null : () => _cubit.save(_note.text),
                  child: Text(l10n.save),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _customer(CreditFormState state) {
    final l10n = context.l10n;
    final t = context.tokens;
    final name = state.customer?.name;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LabeledField(
          label: l10n.creditCustomer,
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: _chooseCustomer,
                  borderRadius: BorderRadius.circular(AppSizes.radiusInput),
                  child: Container(
                    height: AppSizes.inputHeight,
                    alignment: AlignmentDirectional.centerStart,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: t.surface,
                      borderRadius: BorderRadius.circular(AppSizes.radiusInput),
                      border: Border.all(
                        color: state.customerMissing
                            ? t.dangerText
                            : t.border,
                      ),
                    ),
                    child: Text(
                      name ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextTheme.body.copyWith(color: t.textPrimary),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: _chooseCustomer,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, AppSizes.inputHeight),
                  foregroundColor: t.textPrimary,
                  side: BorderSide(color: t.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusInput),
                  ),
                ),
                child: Text(l10n.creditChoose),
              ),
            ],
          ),
        ),
        if (state.customerMissing) ...[
          const SizedBox(height: AppSizes.fieldGap),
          ErrorLine(l10n.creditChooseCustomer),
        ],
      ],
    );
  }

  Widget _lines(CreditFormState state) {
    final l10n = context.l10n;
    final t = context.tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text.rich(
          TextSpan(
            text: l10n.creditItems,
            children: [
              TextSpan(
                text: ' ${l10n.optional}',
                style: AppTextTheme.label.copyWith(
                  color: t.textMuted,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
          style: AppTextTheme.sectionTitle.copyWith(color: t.textPrimary),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.creditItemsHint,
          style: AppTextTheme.hint.copyWith(color: t.textMuted, fontSize: 13),
        ),
        for (final (i, line) in state.lines.indexed)
          _LineRow(
            line: line,
            currency: state.currency,
            khrPerUsd: state.khrPerUsd,
            divider: i < state.lines.length - 1,
            onQty: (qty) => _cubit.setQty(line.id, qty),
          ),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton.icon(
            onPressed: _addItems,
            style: TextButton.styleFrom(
              foregroundColor: t.textPrimary,
              minimumSize: const Size(0, AppSizes.minTapTarget),
              padding: EdgeInsets.zero,
            ),
            icon: const Icon(Icons.add_rounded, size: 20),
            label: Text(
              l10n.creditAddItems,
              style: AppTextTheme.label.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  Widget _amount(CreditFormState state) {
    final l10n = context.l10n;
    final total = state.total;
    if (state.lines.isEmpty) {
      return LabeledField(
        label: l10n.amount,
        child: MoneyInput(
          key: const ValueKey('typed-amount'),
          value: state.amount == null
              ? null
              : Money(state.amount!, state.currency),
          currency: state.currency,
          khrPerUsd: state.khrPerUsd,
          textInputAction: TextInputAction.next,
          onText: (text, currency) =>
              _cubit.setTyped(Money.tryParse(text, currency)?.amount, currency),
        ),
      );
    }
    // With lines the amount is their sum and cannot be typed (decision 9).
    return LabeledField(
      label: l10n.amount,
      hint: l10n.creditAmountHint,
      child: MoneyInput(
        // The field reads its value once: a new total or currency resets it.
        key: ValueKey('computed-amount-${state.currency}-${total?.amount}'),
        value: total,
        currency: state.currency,
        khrPerUsd: state.khrPerUsd,
        readOnly: true,
        onText: (_, currency) {
          if (currency != state.currency) _cubit.setCurrency(currency);
        },
      ),
    );
  }

  Widget _takenAt(CreditFormState state) {
    final l10n = context.l10n;
    final wall = state.takenAt.toPhnomPenh();
    return LabeledField(
      label: l10n.creditTakenAt,
      child: DateTimeField(
        date: DateTime(wall.year, wall.month, wall.day),
        dateText: l10n.formatDate(wall),
        time: TimeOfDay(hour: wall.hour, minute: wall.minute),
        timeText: l10n.formatTime(wall),
        onDateChanged: (d) => _cubit.setTakenAt(
          _utc(d.year, d.month, d.day, wall.hour, wall.minute),
        ),
        onTimeChanged: (time) => _cubit.setTakenAt(
          _utc(wall.year, wall.month, wall.day, time.hour, time.minute),
        ),
      ),
    );
  }
}

/// `ទឹក` with `1 ដប · 3,000 ៛`, an outlined stepper (0 removes it) and
/// the line's total in the Credit's currency.
class _LineRow extends StatelessWidget {
  const _LineRow({
    required this.line,
    required this.currency,
    required this.khrPerUsd,
    required this.divider,
    required this.onQty,
  });

  final CreditLine line;
  final Currency currency;
  final int khrPerUsd;
  final bool divider;
  final ValueChanged<int> onQty;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final total = line.total.convertTo(currency, khrPerUsd: khrPerUsd);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: divider ? Border(bottom: BorderSide(color: t.divider)) : null,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  line.name,
                  style: AppTextTheme.label.copyWith(
                    color: t.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '1 ${line.unit} · '
                  '${Money(line.unitPrice, line.currency).format()}',
                  style: AppTextTheme.hint.copyWith(
                    color: t.textMuted,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: t.border),
              borderRadius: BorderRadius.circular(AppSizes.radiusInput),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Step(
                  icon: Icons.remove_rounded,
                  onTap: () => onQty(line.qty - 1),
                ),
                SizedBox(
                  width: 24,
                  child: Text(
                    '${line.qty}',
                    textAlign: TextAlign.center,
                    style: AppTextTheme.body.copyWith(
                      color: t.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                _Step(
                  icon: Icons.add_rounded,
                  onTap: () => onQty(line.qty + 1),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 72,
            child: Text(
              total.formatNumber(),
              textAlign: TextAlign.end,
              style: AppTextTheme.label.copyWith(
                color: t.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(AppSizes.radiusInput),
    child: SizedBox(
      width: 36,
      height: 40,
      child: Icon(icon, size: 20, color: context.tokens.textPrimary),
    ),
  );
}

/// The optional `ត្រូវសង` day: a calendar button with `ជ្រើសថ្ងៃ` until one
/// is chosen, then the date and a clear button.
class _DueDateField extends StatelessWidget {
  const _DueDateField({
    required this.day,
    required this.onTap,
    required this.onClear,
  });

  final DateTime? day;
  final VoidCallback onTap;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final t = context.tokens;
    final day = this.day;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.radiusInput),
      child: Container(
        height: AppSizes.inputHeight,
        padding: const EdgeInsets.only(left: 14),
        decoration: BoxDecoration(
          color: t.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusInput),
          border: Border.all(color: t.border),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_rounded, size: 18, color: t.textSecondary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                day == null ? l10n.creditPickDate : l10n.formatDate(day),
                style: AppTextTheme.body.copyWith(
                  color: day == null ? t.placeholder : t.textPrimary,
                ),
              ),
            ),
            if (day != null)
              IconButton(
                onPressed: onClear,
                tooltip: MaterialLocalizations.of(context).deleteButtonTooltip,
                icon: Icon(Icons.close_rounded, size: 18, color: t.textMuted),
              ),
          ],
        ),
      ),
    );
  }
}
