import 'package:flutter/material.dart';
import 'package:my_app/app/app.dart';
import 'package:my_app/income/income.dart';
import 'package:my_app/l10n/l10n.dart';

class IncomeFilterSheet extends StatefulWidget {
  const IncomeFilterSheet({
    required this.onApply,
    this.initialFromDate,
    this.initialToDate,
    this.initialBankFilter,
    this.initialRecordFilter = NotificationRecordFilter.all,
    super.key,
  });

  final DateTime? initialFromDate;
  final DateTime? initialToDate;
  final BankApp? initialBankFilter;
  final NotificationRecordFilter initialRecordFilter;
  final void Function(
    DateTime? fromDate,
    DateTime? toDate,
    BankApp? bankFilter,
    NotificationRecordFilter recordFilter,
  ) onApply;

  @override
  State<IncomeFilterSheet> createState() => _IncomeFilterSheetState();
}

class _IncomeFilterSheetState extends State<IncomeFilterSheet> {
  late DateTime? _fromDate = widget.initialFromDate;
  late DateTime? _toDate = widget.initialToDate;
  late BankApp? _bankFilter = widget.initialBankFilter;
  late NotificationRecordFilter _recordFilter = widget.initialRecordFilter;

  Future<void> _pickDate(bool isFrom) async {
    final current = isFrom ? _fromDate : _toDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      if (isFrom) {
        _fromDate = picked;
      } else {
        _toDate = picked;
      }
    });
  }

  String _formatDate(DateTime? date) {
    if (date == null) return context.l10n.notSet;
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final inputTheme = Theme.of(context).inputDecorationTheme;

    return AppBottomSheet(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.filterIncome,
              style: AppTextTheme.title.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              readOnly: true,
              onTap: () => _pickDate(true),
              controller: TextEditingController(text: _formatDate(_fromDate)),
              decoration: InputDecoration(
                labelText: context.l10n.fromDate,
                filled: inputTheme.filled,
                fillColor: inputTheme.fillColor,
                border: inputTheme.border,
                enabledBorder: inputTheme.enabledBorder,
                focusedBorder: inputTheme.focusedBorder,
                suffixIcon: const Icon(Icons.calendar_today, size: 20),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              readOnly: true,
              onTap: () => _pickDate(false),
              controller: TextEditingController(text: _formatDate(_toDate)),
              decoration: InputDecoration(
                labelText: context.l10n.toDate,
                filled: inputTheme.filled,
                fillColor: inputTheme.fillColor,
                border: inputTheme.border,
                enabledBorder: inputTheme.enabledBorder,
                focusedBorder: inputTheme.focusedBorder,
                suffixIcon: const Icon(Icons.calendar_today, size: 20),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              context.l10n.bankLabel,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: Text(context.l10n.all),
                  selected: _bankFilter == null,
                  onSelected: (_) => setState(() => _bankFilter = null),
                ),
                for (final bank in [
                  BankApp.aba,
                  BankApp.chipMong,
                  BankApp.acleda,
                ])
                  ChoiceChip(
                    label: Text(bank.label),
                    selected: _bankFilter == bank,
                    onSelected: (_) => setState(() => _bankFilter = bank),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              context.l10n.trackedNotifications,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: Text(context.l10n.allRecords),
                  selected: _recordFilter == NotificationRecordFilter.all,
                  onSelected: (_) => setState(
                    () => _recordFilter = NotificationRecordFilter.all,
                  ),
                ),
                ChoiceChip(
                  label: Text(context.l10n.incomeOnly),
                  selected: _recordFilter == NotificationRecordFilter.income,
                  onSelected: (_) => setState(
                    () => _recordFilter = NotificationRecordFilter.income,
                  ),
                ),
                ChoiceChip(
                  label: Text(context.l10n.expenseOnly),
                  selected: _recordFilter == NotificationRecordFilter.expense,
                  onSelected: (_) => setState(
                    () => _recordFilter = NotificationRecordFilter.expense,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    widget.onApply(
                      null,
                      null,
                      null,
                      NotificationRecordFilter.all,
                    );
                    Navigator.pop(context);
                  },
                  child: Text(context.l10n.reset),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    if (_fromDate != null &&
                        _toDate != null &&
                        _fromDate!.isAfter(_toDate!)) {
                      final temp = _fromDate;
                      _fromDate = _toDate;
                      _toDate = temp;
                    }
                    widget.onApply(
                      _fromDate,
                      _toDate,
                      _bankFilter,
                      _recordFilter,
                    );
                    Navigator.pop(context);
                  },
                  child: Text(context.l10n.apply),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
