import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_app/app/app.dart';
import 'package:my_app/customer/customer.dart';
import 'package:my_app/l10n/l10n.dart';

class CustomerPage extends StatelessWidget {
  const CustomerPage({required this.customerBloc, super.key});

  final CustomerBloc customerBloc;

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: customerBloc,
      child: const _CustomerPageContent(),
    );
  }
}

class _CustomerPageContent extends StatelessWidget {
  const _CustomerPageContent();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.l10n.customers,
          style: AppTextTheme.title,
        ),
      ),
      body: BlocConsumer<CustomerBloc, CustomerState>(
        listener: (context, state) {
          switch (state) {
            case CustomerError():
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    state.message,
                    style: AppTextTheme.body,
                  ),
                ),
              );
            default:
          }
        },
        builder: (context, state) {
          final items = state is CustomerLoaded ? state.customers : <CustomerModel>[];

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return _buildAddCustomerButton(context);
              }
              final item = items[index - 1];
              return _buildCustomerTile(context, item);
            },
          );
        },
      ),
    );
  }

  Widget _buildAddCustomerButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: ElevatedButton.icon(
        onPressed: () => _showCustomerDialog(context),
        icon: const Icon(Icons.add),
        label: Text(
          context.l10n.add,
          style: AppTextTheme.body,
        ),
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 50),
        ),
      ),
    );
  }

  Widget _buildCustomerTile(BuildContext context, CustomerModel item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.only(left: 12),
        title: Text(
          item.name,
          style: AppTextTheme.body,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _showCustomerDialog(context, item: item),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _showDeleteConfirmation(context, item),
            ),
          ],
        ),
      ),
    );
  }

  void _showCustomerDialog(BuildContext context, {CustomerModel? item}) {
    final isEdit = item != null;
    final controller = TextEditingController(text: item?.name ?? '');

    showDialog<void>(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<CustomerBloc>(),
        child: AlertDialog(
          title: Text(
            isEdit ? context.l10n.editCustomer : context.l10n.addCustomer,
            style: AppTextTheme.title,
          ),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: context.l10n.customerName,
              labelStyle: AppTextTheme.body,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                context.l10n.cancel,
                style: AppTextTheme.caption,
              ),
            ),
            TextButton(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  final bloc = context.read<CustomerBloc>();
                  if (isEdit) {
                    final updatedCustomer = item.copyWith(name: controller.text);
                    bloc.add(UpdateCustomerEvent(updatedCustomer));
                  } else {
                    bloc.add(
                      CreateCustomerEvent(
                        CustomerModel(
                          id: 0,
                          name: controller.text,
                        ),
                      ),
                    );
                  }
                  Navigator.pop(context);
                }
              },
              child: Text(
                isEdit ? context.l10n.saveChanges : context.l10n.addItem,
                style: AppTextTheme.caption,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, CustomerModel item) {
    showDialog<void>(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<CustomerBloc>(),
        child: AlertDialog(
          title: Text(
            context.l10n.deleteCustomer,
            style: AppTextTheme.title,
          ),
          content: Text(
            '${context.l10n.confirmDelete} ${item.name}?',
            style: AppTextTheme.body,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                context.l10n.cancel,
                style: AppTextTheme.caption,
              ),
            ),
            TextButton(
              onPressed: () {
                context.read<CustomerBloc>().add(DeleteCustomerEvent(item));
                Navigator.pop(context);
              },
              child: Text(
                context.l10n.delete,
                style: AppTextTheme.caption,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// The getter 'customers' isn't defined for the type 'AppLocalizations'.
// Try importing the library that defines 'customers', correcting the name to the name of an existing getter, or defining a getter or field named 'customers'.
// The getter 'editCustomer' isn't defined for the type 'AppLocalizations'.
// Try importing the library that defines 'customers', correcting the name to the name of an existing getter, or defining a getter or field named 'customers'.
// The getter 'addCustomer' isn't defined for the type 'AppLocalizations'.
// Try importing the library that defines 'customers', correcting the name to the name of an existing getter, or defining a getter or field named 'customers'.
// The getter 'customerName' isn't defined for the type 'AppLocalizations'.
// Try importing the library that defines 'customers', correcting the name to the name of an existing getter, or defining a getter or field named 'customers'.
// The getter 'deleteCustomer' isn't defined for the type 'AppLocalizations'.
// Try importing the library that defines 'customers', correcting the name to the name of an existing getter, or defining a getter or field named 'customers'.
