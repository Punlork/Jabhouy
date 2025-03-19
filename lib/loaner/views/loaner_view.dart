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
          LoanerLoading() => ListView.builder(
              controller: controller,
              physics: const BouncingScrollPhysics().applyTo(const AlwaysScrollableScrollPhysics()),
              padding: const EdgeInsets.all(16),
              itemCount: 5,
              itemBuilder: (context, index) => const LoanerItemShimmer(),
            ),
          LoanerLoaded(:final loaners) => RefreshIndicator(
              onRefresh: () async => context.read<LoanerBloc>().add(LoadLoaners()),
              child: loaners.isEmpty
                  ? const Center(child: Text('No loaners available'))
                  : ListView.builder(
                      controller: controller,
                      physics: const BouncingScrollPhysics().applyTo(const AlwaysScrollableScrollPhysics()),
                      padding: const EdgeInsets.all(16),
                      itemCount: loaners.length,
                      itemBuilder: (context, index) {
                        final loaner = loaners[index];
                        return LoanerItem(
                          loaner: loaner,
                          onEdit: (loaner) => context.pushNamed(
                            AppRoutes.formLoaner,
                            extra: {
                              'existingLoaner': loaner,
                              'loanerBloc': context.read<LoanerBloc>(),
                            },
                          ),
                          onDelete: (loaner) => context.read<LoanerBloc>().add(DeleteLoaner(loaner)),
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
