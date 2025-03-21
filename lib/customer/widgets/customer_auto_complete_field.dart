import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:my_app/app/app.dart';
import 'package:my_app/customer/customer.dart';
import 'package:my_app/l10n/l10n.dart';

class CustomerAutocompleteField extends StatelessWidget {
  const CustomerAutocompleteField({
    required this.controller,
    required this.label,
    super.key,
    this.required = false,
    this.focusNode,
    this.padding = const EdgeInsets.only(bottom: 16),
    this.onSelected,
    this.validator,
    this.direction,
  });
  final TextEditingController controller;
  final String label;
  final bool required;
  final FocusNode? focusNode;
  final EdgeInsetsGeometry padding;
  final void Function(CustomerModel)? onSelected;
  final String? Function(String?)? validator;
  final VerticalDirection? direction;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: padding,
      child: BlocBuilder<CustomerBloc, CustomerState>(
        builder: (context, state) => TypeAheadField<CustomerModel>(
          controller: controller,
          direction: direction,
          builder: (context, _, focusNode) => CustomTextFormField(
            controller: controller,
            hintText: '',
            labelText: required ? '$label *' : label,
            focusNode: this.focusNode ?? focusNode,
            useCustomBorder: false,
            showClearButton: true,
            validator: validator ?? (required ? (value) => value!.isEmpty ? l10n.nameRequired(label) : null : null),
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              labelStyle: AppTextTheme.body,
              fillColor: Colors.transparent,
            ),
            onCleared: controller.clear,
          ),
          suggestionsCallback: (pattern) async {
            final currentState = state.asType<CustomerLoaded>();
            if (currentState == null) return [];
            return currentState.customers
                .where(
                  (customer) => customer.name.toLowerCase().contains(pattern.toLowerCase()),
                )
                .toList();
          },
          constraints: const BoxConstraints(maxHeight: 200),
          itemBuilder: (context, CustomerModel suggestion) {
            final number = state.asType<CustomerLoaded>()?.customers.indexOf(suggestion) ?? -1;
            return ListTile(
              title: Text('${number + 1}. ${suggestion.name}'),
            );
          },
          onSelected: onSelected,
        ),
      ),
    );
  }
}
