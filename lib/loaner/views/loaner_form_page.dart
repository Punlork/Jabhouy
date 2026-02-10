import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:my_app/app/app.dart';
import 'package:my_app/customer/customer.dart';
import 'package:my_app/l10n/arb/app_localizations.dart';
import 'package:my_app/loaner/loaner.dart';

class LoanerFormPage extends StatelessWidget {
  const LoanerFormPage({
    required this.loanerBloc,
    required this.customerBloc,
    this.existingLoaner,
    super.key,
  });

  final LoanerModel? existingLoaner;
  final LoanerBloc loanerBloc;
  final CustomerBloc customerBloc;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: loanerBloc),
        BlocProvider.value(value: customerBloc),
      ],
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
  CustomerModel? _selectedCustomer;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();

    _controllers = {
      'name': TextEditingController(),
      'amount': TextEditingController(),
      'note': TextEditingController(),
      'date': TextEditingController(),
    };

    _initialTextValues = {};

    if (widget.existingLoaner != null) {
      final loaner = widget.existingLoaner!;
      _controllers['name']!.text = loaner.customer?.name ?? '';
      _controllers['amount']!.text = loaner.amount.toString();
      _controllers['note']!.text = loaner.note ?? '';
      _controllers['date']!.text = loaner.displayDate;

      _initialTextValues['name'] = loaner.customer?.name ?? '';
      _initialTextValues['amount'] = loaner.amount.toString();
      _initialTextValues['note'] = loaner.note ?? '';
      _initialTextValues['date'] = loaner.displayDate;

      _selectedCustomer = loaner.customer;
      _selectedDate = loaner.createdAt;
    } else {
      _initialTextValues['name'] = '';
      _initialTextValues['amount'] = '';
      _initialTextValues['note'] = '';
      _initialTextValues['date'] = DateFormat('dd MMM yyyy').format(DateTime.now());
      _controllers['date']!.text = DateFormat('dd MMM yyyy').format(DateTime.now());
    }

    _controllers.forEach((key, controller) {
      controller.addListener(_detectChanges);
    });
  }

  void _submitLoanerWithCustomer(CustomerModel customer) {
    final loanerBloc = context.read<LoanerBloc>();
    final loaner = LoanerModel(
      id: widget.existingLoaner?.id ?? -1,
      customerId: customer.id,
      amount: int.tryParse(_controllers['amount']!.text) ?? 0,
      note: _controllers['note']!.text.isEmpty ? null : _controllers['note']!.text,
      createdAt: _selectedDate,
    );

    if (widget.existingLoaner != null) {
      loanerBloc.add(UpdateLoaner(loaner));
    } else {
      loanerBloc.add(AddLoaner(loaner));
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      helpText: l10n.toDate,
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _controllers['date']!.text = DateFormat('dd MMM yyyy').format(picked);
        _hasChanges = true;
      });
    }
  }

  void _submitLoaner() {
    if (!_formKey.currentState!.validate()) return;

    final customerBloc = context.read<CustomerBloc>();
    final name = _controllers['name']!.text;

    if (_selectedCustomer == null) {
      final newCustomer = CustomerModel(
        id: -1,
        name: name,
      );
      customerBloc.add(CreateCustomerEvent(newCustomer));
    } else {
      _submitLoanerWithCustomer(_selectedCustomer!);
    }
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

  Widget _buildTextField({
    required String key,
    required String label,
    bool required = false,
    bool isAmount = false,
    TextInputType keyboardType = TextInputType.text,
    TextInputAction textInputAction = TextInputAction.next,
    int? maxLines,
    FocusNode? focusNode,
    EdgeInsetsGeometry? padding,
    TextEditingController? controller,
    TextCapitalization? textCapitalization,
  }) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: padding ?? const EdgeInsets.only(bottom: 16),
      child: CustomTextFormField(
        controller: controller ?? _controllers[key]!,
        focusNode: focusNode,
        hintText: '',
        textCapitalization: textCapitalization,
        labelText: required ? '$label *' : label,
        keyboardType: maxLines != null ? TextInputType.multiline : (isAmount ? TextInputType.number : keyboardType),
        action: textInputAction,
        useCustomBorder: false,
        onTapOutside: (_) {},
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
            widget.existingLoaner != null ? l10n.editLoaner : l10n.addNewLoaner,
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
        body: Stack(
          children: [
            MultiBlocListener(
              listeners: [
                BlocListener<LoanerBloc, LoanerState>(
                  listener: (context, state) {
                    if (state is LoanerLoaded) context.pop();
                  },
                ),
                BlocListener<CustomerBloc, CustomerState>(
                  listener: (context, state) {
                    if (state is CustomerCreated && context.mounted) {
                      _submitLoanerWithCustomer(state.customer);
                    }
                  },
                ),
              ],
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomerAutocompleteField(
                        controller: _controllers['name']!,
                        label: l10n.name,
                        required: true,
                        onSelected: (customer) {
                          _selectedCustomer = customer;
                          _controllers['name']?.text = customer.name;
                          FocusManager.instance.primaryFocus?.unfocus();
                          setState(() {});
                        },
                      ),
                      _buildTextField(
                        key: 'amount',
                        label: l10n.amount,
                        required: true,
                        isAmount: true,
                        keyboardType: TextInputType.number,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: TextFormField(
                          controller: _controllers['date'],
                          readOnly: true,
                          onTap: () => _selectDate(context),
                          onTapOutside: (event) => FocusManager.instance.primaryFocus?.unfocus(),
                          decoration: InputDecoration(
                            labelText: l10n.toDate,
                            labelStyle: AppTextTheme.body,
                            border: const OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(8)),
                            ),
                            suffixIcon: const Icon(Icons.calendar_today, size: 20),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                          ),
                          validator: (value) => value!.isEmpty ? l10n.nameRequired(l10n.toDate) : null,
                        ),
                      ),
                      _buildTextField(
                        key: 'note',
                        label: l10n.note,
                        maxLines: 3,
                        textInputAction: TextInputAction.newline,
                      ),
                      const SizedBox(height: 80),
                      // Button removed from here
                    ],
                  ),
                ),
              ),
            ),
            KeyboardVisibilityBuilder(
              builder: (context, isKeyboardVisible) {
                if (!isKeyboardVisible) {
                  return Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: ElevatedButton(
                      onPressed: _submitLoaner,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                      ),
                      child: Text(
                        widget.existingLoaner != null ? l10n.saveChanges : l10n.addLoaner,
                        style: AppTextTheme.body,
                      ),
                    ),
                  );
                } else {
                  return Positioned(
                    bottom: 16,
                    right: 16,
                    child: FloatingActionButton.extended(
                      onPressed: _submitLoaner,
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      label: Text(
                        widget.existingLoaner != null ? l10n.saveChanges : l10n.addLoaner,
                        style: AppTextTheme.body,
                      ),
                      icon: const Icon(Icons.save),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
