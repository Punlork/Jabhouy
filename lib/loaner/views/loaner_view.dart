import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_app/home/home.dart';
import 'package:my_app/loaner/loaner.dart';

void showAddLoanerDialog(BuildContext context, LoanerBloc loanerBloc) {
  final nameController = TextEditingController();
  final amountController = TextEditingController();
  final noteController = TextEditingController();

  showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Add Loaner'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: amountController,
              decoration: const InputDecoration(labelText: 'Amount'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(labelText: 'Note (optional)'),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final name = nameController.text.trim();
              final amount = double.tryParse(amountController.text) ?? 0.0;
              final note = noteController.text.trim();
              if (name.isNotEmpty && amount > 0) {
                final loaner = LoanerModel(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: name,
                  amount: amount,
                  note: note,
                );
                loanerBloc.add(AddLoaner(loaner));
                Navigator.pop(dialogContext);
              }
            },
            child: const Text('Add'),
          ),
        ],
      );
    },
  );
}

class LoanerView extends StatefulWidget {
  const LoanerView({super.key});

  @override
  State<LoanerView> createState() => _LoanerViewState();
}

class _LoanerViewState extends State<LoanerView> with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context);

    final controller = TabScrollManager.of(context)?.getController(1);

    return BlocBuilder<LoanerBloc, LoanerState>(
      builder: (context, state) {
        if (state is LoanerLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is LoanerLoaded) {
          return RefreshIndicator(
            onRefresh: () async {
              context.read<LoanerBloc>().add(LoadLoaners());
              // ignore: inference_failure_on_instance_creation
              await Future.delayed(const Duration(milliseconds: 500));
            },
            child: state.loaners.isEmpty
                ? const Center(child: Text('No loaners available'))
                : ListView.builder(
                    controller: controller,
                    physics: const BouncingScrollPhysics().applyTo(
                      const AlwaysScrollableScrollPhysics(),
                    ),
                    padding: const EdgeInsets.all(16),
                    itemCount: state.loaners.length,
                    itemBuilder: (context, index) {
                      final loaner = state.loaners[index];
                      return Card(
                        elevation: 4,
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(16).copyWith(right: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: .1),
                                child: Icon(
                                  Icons.person,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      loaner.name,
                                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Amount: \$${loaner.amount.toStringAsFixed(2)}',
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            color: Colors.grey[700],
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Note: ${loaner.note.isEmpty ? 'No note' : loaner.note}',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: Colors.grey[600],
                                            fontStyle: loaner.note.isEmpty ? FontStyle.italic : FontStyle.normal,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    color: Theme.of(context).colorScheme.primary,
                                    onPressed: () => _showEditDialog(context, loaner),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete),
                                    color: Colors.red,
                                    onPressed: () => context.read<LoanerBloc>().add(DeleteLoaner(loaner.id)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          );
        } else if (state is LoanerError) {
          return Center(child: Text(state.message));
        }
        return const Center(child: Text('Start by loading loaners'));
      },
    );
  }

  void _showEditDialog(BuildContext context, LoanerModel loaner) {
    final nameController = TextEditingController(text: loaner.name);
    final amountController = TextEditingController(text: loaner.amount.toString());
    final noteController = TextEditingController(text: loaner.note);

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Edit Loaner'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: amountController,
                decoration: const InputDecoration(labelText: 'Amount'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: noteController,
                decoration: const InputDecoration(labelText: 'Note (optional)'),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final name = nameController.text.trim();
                final amount = double.tryParse(amountController.text) ?? 0.0;
                final note = noteController.text.trim();
                if (name.isNotEmpty && amount > 0) {
                  final updatedLoaner = LoanerModel(
                    id: loaner.id,
                    name: name,
                    amount: amount,
                    note: note,
                  );
                  context.read<LoanerBloc>().add(UpdateLoaner(updatedLoaner));
                  Navigator.pop(dialogContext);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  bool get wantKeepAlive => true;
}
