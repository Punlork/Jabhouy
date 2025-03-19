import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:my_app/app/app.dart';
import 'package:my_app/home/home.dart';
import 'package:my_app/loaner/loaner.dart';

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
        return switch (state) {
          LoanerLoading() => const Center(child: CircularProgressIndicator()),
          LoanerLoaded(:final loaners) => RefreshIndicator(
              onRefresh: () async => context.read<LoanerBloc>().add(LoadLoaners()),
              child: loaners.isEmpty
                  ? const Center(child: Text('No loaners available'))
                  : ListView.builder(
                      controller: controller,
                      physics: const BouncingScrollPhysics().applyTo(
                        const AlwaysScrollableScrollPhysics(),
                      ),
                      padding: const EdgeInsets.all(16),
                      itemCount: loaners.length,
                      itemBuilder: (context, index) {
                        final loaner = loaners[index];
                        return Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(16).copyWith(right: 0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    spacing: 12,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        loaner.name,
                                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      Text(
                                        '${loaner.amount} រៀល',
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                              color: Colors.grey[700],
                                            ),
                                      ),
                                      Text(
                                        'Note: ${(loaner.note?.isEmpty ?? true) ? 'No note' : loaner.note}',
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                              color: Colors.grey[600],
                                              fontStyle:
                                                  (loaner.note?.isEmpty ?? true) ? FontStyle.italic : FontStyle.normal,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.edit,
                                        size: 30,
                                      ),
                                      color: Theme.of(context).colorScheme.primary,
                                      onPressed: () => context.pushNamed(
                                        AppRoutes.formLoaner,
                                        extra: {
                                          'existingLoaner': loaner,
                                          'loanerBloc': context.read<LoanerBloc>(),
                                        },
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        size: 30,
                                      ),
                                      color: Colors.red,
                                      onPressed: () => context.read<LoanerBloc>().add(DeleteLoaner(loaner)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          LoanerError() => Center(child: Text(state.message)),
          _ => const SizedBox.shrink(),
        };
      },
    );
  }

  @override
  bool get wantKeepAlive => true;
}
