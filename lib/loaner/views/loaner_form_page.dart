import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:my_app/app/app.dart';
import 'package:my_app/l10n/l10n.dart';
import 'package:my_app/loaner/loaner.dart';

class LoanerFormPage extends StatelessWidget {
  const LoanerFormPage({
    required this.loanerBloc,
    this.existingLoaner,
    super.key,
  });

  final LoanerModel? existingLoaner;
  final LoanerBloc loanerBloc;

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: loanerBloc,
      child: _LoanerFormPageContent(
        existingLoaner: existingLoaner,
      ),
    );
  }
}

class _LoanerFormPageContent extends StatefulWidget {
  const _LoanerFormPageContent({
    this.existingLoaner,
  });

  final LoanerModel? existingLoaner;

  @override
  State<_LoanerFormPageContent> createState() => _LoanerFormPageState();
}

class _LoanerFormPageState extends State<_LoanerFormPageContent> {
  final _formKey = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _controllers;
  bool _hasChanges = false;

  late Map<String, String> _initialTextValues;

  @override
  void initState() {
    super.initState();

    _controllers = {
      'name': TextEditingController(),
      'amount': TextEditingController(),
      'note': TextEditingController(),
    };

    _initialTextValues = {};

    if (widget.existingLoaner != null) {
      final loaner = widget.existingLoaner!;
      _controllers['name']!.text = loaner.name;
      _controllers['amount']!.text = loaner.amount.toString();
      _controllers['note']!.text = loaner.note ?? '';

      _initialTextValues['name'] = loaner.name;
      _initialTextValues['amount'] = loaner.amount.toString();
      _initialTextValues['note'] = loaner.note ?? '';
    } else {
      _initialTextValues['name'] = '';
      _initialTextValues['amount'] = '';
      _initialTextValues['note'] = '';
    }

    _controllers.forEach((key, controller) {
      controller.addListener(_detectChanges);
    });
  }

  @override
  void dispose() {
    _controllers.forEach((_, controller) => controller.dispose());
    super.dispose();
  }

  void _detectChanges() {
    final hasTextChanges = _controllers.entries.any(
      (entry) => entry.value.text != _initialTextValues[entry.key],
    );
    _hasChanges = hasTextChanges;
    setState(() {});
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;

    final l10n = AppLocalizations.of(context);
    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.unsavedChanges, style: AppTextTheme.title),
        content: Text(l10n.confirmDiscardChanges, style: AppTextTheme.body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel, style: AppTextTheme.caption),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(l10n.discard, style: AppTextTheme.caption),
          ),
        ],
      ),
    );

    return shouldPop ?? false;
  }

  void _submitLoaner() {
    if (!_formKey.currentState!.validate()) return;

    final loanerBloc = context.read<LoanerBloc>();
    final loaner = LoanerModel(
      id: widget.existingLoaner?.id ?? -1,
      name: _controllers['name']!.text,
      amount: int.tryParse(_controllers['amount']!.text) ?? 0,
      note: _controllers['note']!.text.isEmpty ? null : _controllers['note']!.text,
    );

    if (widget.existingLoaner != null) {
      loanerBloc.add(UpdateLoaner(loaner));
    } else {
      loanerBloc.add(AddLoaner(loaner));
    }
  }

  Widget _buildTextField({
    required String key,
    required String label,
    bool required = false,
    bool isAmount = false,
    TextInputType keyboardType = TextInputType.text,
    TextInputAction textInputAction = TextInputAction.next,
    int? maxLines,
  }) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: CustomTextFormField(
        controller: _controllers[key]!,
        hintText: '',
        labelText: required ? '$label *' : label,
        keyboardType: maxLines != null ? TextInputType.multiline : (isAmount ? TextInputType.number : keyboardType),
        action: textInputAction,
        useCustomBorder: false,
        validator: required ? (value) => value!.isEmpty ? l10n.nameRequired(label) : null : null,
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          labelStyle: AppTextTheme.body,
          suffixText: isAmount ? 'រៀល' : null,
          suffixStyle: isAmount ? AppTextTheme.caption : null,
        ),
        maxLines: maxLines ?? 1,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop && _hasChanges) {
          final shouldPop = await _onWillPop();
          if (shouldPop && context.mounted) Navigator.pop(context);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.existingLoaner != null ? 'Edit Loaner' : 'Add New Loaner',
            style: AppTextTheme.title,
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              if (!_hasChanges) {
                context.pop();
                return;
              }
              final shouldPop = await _onWillPop();
              if (shouldPop && context.mounted) context.pop();
            },
          ),
        ),
        body: BlocListener<LoanerBloc, LoanerState>(
          listener: (context, state) {
            if (state is LoanerLoaded) context.pop();
          },
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTextField(
                    key: 'name',
                    label: l10n.name,
                    required: true,
                  ),
                  _buildTextField(
                    key: 'amount',
                    label: 'Amount',
                    required: true,
                    isAmount: true,
                    keyboardType: TextInputType.number,
                  ),
                  _buildTextField(
                    key: 'note',
                    label: l10n.note,
                    maxLines: 3,
                    textInputAction: TextInputAction.done,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _submitLoaner,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                    ),
                    child: Text(
                      widget.existingLoaner != null ? 'Save Changes' : 'Add Loaner',
                      style: AppTextTheme.body,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
