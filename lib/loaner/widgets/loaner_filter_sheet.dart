import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_app/app/app.dart';
import 'package:my_app/customer/customer.dart';
import 'package:my_app/l10n/arb/app_localizations.dart';
import 'package:my_app/l10n/l10n.dart';
import 'package:my_app/loaner/loaner.dart';

class LoanerFilterSheet extends StatefulWidget {
  const LoanerFilterSheet({
    required this.onApply,
    this.initialFromDate,
    this.initialToDate,
    this.initialLoanerFilter,
    super.key,
  });

  final DateTime? initialFromDate;
  final DateTime? initialToDate;
  final CustomerModel? initialLoanerFilter;
  final void Function(
    DateTime? fromDate,
    DateTime? toDate,
    CustomerModel? loanerFilter,
  ) onApply;

  @override
  State<LoanerFilterSheet> createState() => _LoanerFilterSheetState();
}

class _LoanerFilterSheetState extends State<LoanerFilterSheet> {
  late DateTime? _fromDate = widget.initialFromDate;
  late DateTime? _toDate = widget.initialToDate;
  late CustomerModel? _loanerFilter;
  final TextEditingController _loanerController = TextEditingController();
  final TextEditingController _fromDateController = TextEditingController();
  final TextEditingController _toDateController = TextEditingController();

  bool get isDisabled =>
      _fromDate == null && _toDate == null && _loanerFilter == null;

  @override
  void initState() {
    super.initState();
    _loanerFilter = widget.initialLoanerFilter;
    _loanerController.text = _loanerFilter?.name ?? '';
    _syncDateControllers();
  }

  @override
  void dispose() {
    _loanerController.dispose();
    _fromDateController.dispose();
    _toDateController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isFromDate) async {
    final initialDate = (isFromDate ? _fromDate : _toDate) ?? DateTime.now();
    final firstDate = DateTime(2000);
    final lastDate = DateTime(2101);

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (picked != null) {
      setState(() {
        if (isFromDate) {
          _fromDate = picked;
        } else {
          _toDate = picked;
        }
        _syncDateControllers();
      });
    }
  }

  void _adjustDatesIfNeeded() {
    if (_fromDate != null && _toDate != null && _fromDate!.isAfter(_toDate!)) {
      final temp = _fromDate;
      _fromDate = _toDate;
      _toDate = temp;
      _syncDateControllers();
    }
  }

  void _syncDateControllers() {
    _fromDateController.text = _formatToRFC3339Date(_fromDate);
    _toDateController.text = _formatToRFC3339Date(_toDate);
  }

  String _formatToRFC3339Date(DateTime? date) {
    if (date == null) return context.l10n.notSet;
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final inputTheme = Theme.of(context).inputDecorationTheme;
    final l10n = AppLocalizations.of(context);

    return AppBottomSheet(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.filterLoaners,
              style: AppTextTheme.title.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _fromDateController,
              readOnly: true,
              onTap: () => _selectDate(context, true),
              decoration: InputDecoration(
                labelText: l10n.fromDate,
                hintText: _fromDate == null ? l10n.notSet : null,
                filled: inputTheme.filled,
                fillColor: inputTheme.fillColor,
                border: inputTheme.border,
                enabledBorder: inputTheme.enabledBorder,
                focusedBorder: inputTheme.focusedBorder,
                suffixIcon: const Icon(Icons.calendar_today, size: 20),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _toDateController,
              readOnly: true,
              onTap: () => _selectDate(context, false),
              decoration: InputDecoration(
                labelText: l10n.toDate,
                hintText: _toDate == null ? l10n.notSet : null,
                filled: inputTheme.filled,
                fillColor: inputTheme.fillColor,
                border: inputTheme.border,
                enabledBorder: inputTheme.enabledBorder,
                focusedBorder: inputTheme.focusedBorder,
                suffixIcon: const Icon(Icons.calendar_today, size: 20),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
              ),
            ),
            const SizedBox(height: 16),
            CustomerAutocompleteField(
              controller: _loanerController,
              label: l10n.name,
              direction: VerticalDirection.up,
              onSelected: (customer) {
                _loanerFilter = customer;
                _loanerController.text = customer.name;
                FocusManager.instance.primaryFocus?.unfocus();
                setState(() {});
              },
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    context
                        .read<LoanerBloc>()
                        .add(LoadLoaners(forceRefresh: true));
                    Navigator.pop(context);
                  },
                  child: Text(l10n.reset),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: isDisabled
                      ? null
                      : () {
                          _adjustDatesIfNeeded();
                          context.read<LoanerBloc>().add(
                                LoadLoaners(
                                  fromDate: _fromDate,
                                  toDate: _toDate,
                                  loanerFilter: _loanerFilter,
                                  forceRefresh: true,
                                ),
                              );
                          Navigator.pop(context);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDisabled
                        ? colorScheme.surfaceContainerHighest
                        : colorScheme.primary,
                    foregroundColor: isDisabled
                        ? colorScheme.onSurfaceVariant
                        : colorScheme.onPrimary,
                  ),
                  child: Text(l10n.apply),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
