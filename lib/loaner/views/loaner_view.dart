import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import 'package:my_app/app/app.dart';
import 'package:my_app/customer/customer.dart';
import 'package:my_app/home/home.dart';
import 'package:my_app/l10n/l10n.dart';
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

    return BlocBuilder<LoanerBloc, LoanerState>(
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
                ? EmptyView(msg: context.l10n.noLoanerFound)
                : ListView.separated(
                    separatorBuilder: (context, index) => index != items.length - 1
                        ? Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Divider(
                              color: Colors.grey.shade200,
                            ),
                          )
                        : const SizedBox(),
                    controller: controller,
                    physics: const BouncingScrollPhysics().applyTo(const AlwaysScrollableScrollPhysics()),
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length + 2,
                    itemBuilder: (context, index) {
                      if (index == items.length) {
                        if (pagination.hasNext) {
                          return const CustomLoading();
                        } else {
                          return const SizedBox.shrink();
                        }
                      }
                      if (index == items.length + 1) {
                        return const SizedBox(height: 70);
                      }

                      final loaner = items[index];
                      return _buildLoanerItem(context, loaner);
                    },
                  ),
          ),
        LoanerError() => Center(child: Text(state.message)),
        _ => const SizedBox.shrink(),
      },
    );
  }

  Widget _buildLoanerItem(
    BuildContext context,
    LoanerModel loaner,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return Stack(
      children: [
        Positioned.fill(
          child: Builder(
            builder: (context) => Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [colorScheme.primary, colorScheme.primaryContainer],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        Slidable(
          key: ValueKey(loaner.id),
          endActionPane: ActionPane(
            motion: const StretchMotion(),
            children: [
              Theme(
                data: Theme.of(context).copyWith(
                  outlinedButtonTheme: const OutlinedButtonThemeData(
                    style: ButtonStyle(
                      iconColor: WidgetStatePropertyAll(Colors.white),
                    ),
                  ),
                ),
                child: SlidableAction(
                  onPressed: (context) {
                    context.pushNamed(
                      AppRoutes.formLoaner,
                      extra: {
                        'existingLoaner': loaner,
                        'loanerBloc': context.read<LoanerBloc>(),
                        'customerBloc': context.read<CustomerBloc>(),
                      },
                    );
                  },
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  icon: Icons.edit,
                ),
              ),
              Theme(
                data: Theme.of(context).copyWith(
                  outlinedButtonTheme: const OutlinedButtonThemeData(
                    style: ButtonStyle(
                      iconColor: WidgetStatePropertyAll(Colors.red),
                    ),
                  ),
                ),
                child: SlidableAction(
                  onPressed: (context) {
                    context.read<LoanerBloc>().add(DeleteLoaner(loaner));
                  },
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.red,
                  icon: Icons.delete,
                ),
              ),
            ],
          ),
          child: LoanerItem(
            loaner: loaner,
            onMarkAsPaid: ({bool isPaid = false}) => context.read<LoanerBloc>().add(
                  UpdateLoaner(
                    loaner.copyWith(
                      isPaid: isPaid,
                      customerId: loaner.customer?.id,
                    ),
                  ),
                ),
          ),
        ),
      ],
    );
  }

  @override
  bool get wantKeepAlive => true;
}
