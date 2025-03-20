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

class _LoanerViewState extends State<LoanerView> with AutomaticKeepAliveClientMixin, InfiniteScrollMixin<LoanerView> {
  @override
  void initState() {
    super.initState();
    setupScrollListener(context);
  }

  @override
  ScrollController? getScrollController(BuildContext context) => TabScrollManager.of(context)?.getController(1);

  @override
  void onScrollToBottom() {
    if (!mounted) return;
    final state = context.read<LoanerBloc>().state.asLoaded;
    if (state != null && state.pagination.hasNext) {
      context.read<LoanerBloc>().add(
            LoadLoaners(
              page: state.pagination.page + 1,
              limit: state.pagination.limit,
            ),
          );
    }
  }

  @override
  void dispose() {
    super.dispose();
    disposeScrollListener();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final child = BlocBuilder<LoanerBloc, LoanerState>(
      builder: (context, state) => switch (state) {
        LoanerLoading() => ListView.builder(
            controller: controller,
            physics: const BouncingScrollPhysics().applyTo(const AlwaysScrollableScrollPhysics()),
            padding: const EdgeInsets.all(16),
            itemCount: 5,
            itemBuilder: (context, index) => const LoanerItemShimmer(),
          ),
        LoanerLoaded(:final items, :final pagination) => RefreshIndicator(
            onRefresh: () async => context.read<LoanerBloc>().add(
                  LoadLoaners(
                    forceRefresh: true,
                    page: 1,
                    limit: 10,
                  ),
                ),
            child: items.isEmpty
                ? const Center(child: Text('No loaners available'))
                : ListView.builder(
                    controller: controller,
                    physics: const BouncingScrollPhysics().applyTo(const AlwaysScrollableScrollPhysics()),
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length + 1,
                    itemBuilder: (context, index) {
                      if (index == items.length) {
                        if (pagination.hasNext) {
                          return const CustomLoading();
                        } else {
                          return const EndOfListIndicator();
                        }
                      }

                      // Otherwise, show the loaner item
                      final loaner = items[index];
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
      },
    );

    return child;
  }

  @override
  bool get wantKeepAlive => true;
}
