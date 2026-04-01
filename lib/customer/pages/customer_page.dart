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
    final colorScheme = Theme.of(context).colorScheme;

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
                  backgroundColor: colorScheme.inverseSurface,
                  content: Text(
                    state.message,
                    style: AppTextTheme.body.copyWith(
                      color: colorScheme.onInverseSurface,
                    ),
                  ),
                ),
              );
            default:
          }
        },
        builder: (context, state) {
          final items =
              state is CustomerLoaded ? state.customers : <CustomerModel>[];
          final syncMessage =
              state is CustomerLoaded ? state.syncMessage : null;
          final bannerCount = syncMessage == null ? 0 : 1;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length + 1 + bannerCount,
            itemBuilder: (context, index) {
              if (index == 0) {
                return _buildAddCustomerButton(context);
              }
              if (syncMessage != null && index == 1) {
                return _buildSyncBanner(
                  context,
                  syncMessage,
                  state is CustomerLoaded && state.isOffline,
                );
              }
              final item = items[index - 1 - bannerCount];
              return _buildCustomerTile(context, item);
            },
          );
        },
      ),
    );
  }

  Widget _buildSyncBanner(
    BuildContext context,
    String message,
    bool isOffline,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            isOffline ? Icons.cloud_off_rounded : Icons.sync_rounded,
            size: 18,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: AppTextTheme.caption.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddCustomerButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          minimumSize: const Size(double.infinity, 50),
        ),
        onPressed: () => _showCustomerDialog(context),
        icon: const Icon(Icons.add),
        label: Text(
          context.l10n.add,
          style: AppTextTheme.body,
        ),
      ),
    );
  }

  Widget _buildCustomerTile(BuildContext context, CustomerModel item) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Theme.of(context).cardTheme.color,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.only(left: 12),
        title: Text(
          item.name,
          style: AppTextTheme.body.copyWith(
            color: colorScheme.onSurface,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                Icons.edit,
                color: colorScheme.onSurfaceVariant,
              ),
              onPressed: () => _showCustomerDialog(context, item: item),
            ),
            IconButton(
              icon: Icon(
                Icons.delete,
                color: colorScheme.error,
              ),
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
    final colorScheme = Theme.of(context).colorScheme;

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
            style: AppTextTheme.body.copyWith(
              color: colorScheme.onSurface,
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
                    final updatedCustomer =
                        item.copyWith(name: controller.text);
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
              style: TextButton.styleFrom(
                foregroundColor: colorScheme.primary,
              ),
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
    final colorScheme = Theme.of(context).colorScheme;

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
              style: TextButton.styleFrom(
                foregroundColor: colorScheme.error,
              ),
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
