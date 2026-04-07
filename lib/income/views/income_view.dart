import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_app/app/app.dart';
import 'package:my_app/home/home.dart';
import 'package:my_app/income/income.dart';
import 'package:my_app/l10n/l10n.dart';

class IncomeView extends StatefulWidget {
  const IncomeView({super.key});

  @override
  State<IncomeView> createState() => _IncomeViewState();
}

class _IncomeViewState extends State<IncomeView>
    with
        AutomaticKeepAliveClientMixin<IncomeView>,
        InfiniteScrollMixin<IncomeView> {
  @override
  void initState() {
    super.initState();
    setupScrollListener(context);
  }

  @override
  ScrollController? getScrollController(BuildContext context) =>
      TabScrollManager.of(context)?.getController(2);

  @override
  void onScrollToBottom() {}

  @override
  void dispose() {
    disposeScrollListener();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final deviceRole = context.select((AppBloc bloc) => bloc.state.deviceRole);

    return BlocListener<AppBloc, AppState>(
      listenWhen: (previous, current) =>
          previous.deviceRole != current.deviceRole,
      listener: (context, state) {
        context.read<IncomeBloc>().add(const RefreshIncomeTrackingStatus());
      },
      child: BlocBuilder<IncomeBloc, IncomeState>(
        builder: (context, state) => switch (state) {
          IncomeLoading() => ListView(
              controller: controller,
              padding: const EdgeInsets.all(16),
              children: const [
                SizedBox(height: 120),
                Center(child: CircularProgressIndicator()),
              ],
            ),
          IncomeLoaded() => RefreshIndicator(
              onRefresh: () async => context
                  .read<IncomeBloc>()
                  .add(const RefreshIncomeTrackingStatus()),
              child: ListView(
                controller: controller,
                physics: const BouncingScrollPhysics()
                    .applyTo(const AlwaysScrollableScrollPhysics()),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                children: [
                  _TrackingStatusCard(
                    state: state,
                    deviceRole: deviceRole,
                  ),
                  const SizedBox(height: 16),
                  IncomePieChart(summary: state.summary),
                  const SizedBox(height: 16),
                  _NotificationList(items: state.items),
                ],
              ),
            ),
          _ => const SizedBox.shrink(),
        },
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}

class _TrackingStatusCard extends StatelessWidget {
  const _TrackingStatusCard({
    required this.state,
    required this.deviceRole,
  });

  final IncomeLoaded state;
  final DeviceRole deviceRole;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final status = state.trackingStatus;
    final isSupported = status?.isSupported ?? false;
    final isEnabled = status?.isAccessEnabled ?? false;
    final isMainDevice = deviceRole.isMain;
    final isBlockedByAnotherMain =
        status?.isBlockedByAnotherMainDevice ?? false;
    final statusMessage = !isMainDevice
        ? context.l10n.subDeviceTrackingDisabled
        : isBlockedByAnotherMain
            ? context.l10n.anotherMainDeviceActive
            : !isSupported
                ? context.l10n.bankNotificationUnsupported
                : isEnabled
                    ? context.l10n.notificationTrackingEnabled
                    : context.l10n.notificationTrackingDisabled;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isEnabled
                    ? Icons.notifications_active_rounded
                    : Icons.notifications_off_rounded,
                color: isEnabled
                    ? AppColorTheme.success
                    : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  context.l10n.notificationTracking,
                  style: AppTextTheme.title.copyWith(
                    color: colorScheme.onSurface,
                    fontSize: 15,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _RolePill(deviceRole: deviceRole),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  statusMessage,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
              if (isMainDevice &&
                  !isBlockedByAnotherMain &&
                  isSupported &&
                  !isEnabled)
                _TinyActionButton(
                  onPressed: () => context
                      .read<IncomeBloc>()
                      .add(const OpenNotificationAccessSettings()),
                  icon: Icons.settings,
                  tooltip: context.l10n.enableNotificationAccess,
                ),
              if (isMainDevice) ...[
                _TinyActionButton(
                  onPressed: () => context
                      .read<IncomeBloc>()
                      .add(const RefreshIncomeTrackingStatus()),
                  icon: Icons.refresh_rounded,
                  tooltip: context.l10n.refreshStatus,
                ),
                if (!kReleaseMode && !isBlockedByAnotherMain)
                  _TinyActionButton(
                    onPressed: () => context.read<IncomeBloc>().add(
                          SeedIncomeDemoData(
                            context.l10n.demoDataAdded,
                            context.l10n.anotherMainDeviceActive,
                          ),
                        ),
                    icon: Icons.bolt_rounded,
                    tooltip: context.l10n.addDemoData,
                  ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _RolePill extends StatelessWidget {
  const _RolePill({required this.deviceRole});

  final DeviceRole deviceRole;

  @override
  Widget build(BuildContext context) {
    final isMainDevice = deviceRole.isMain;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: (isMainDevice ? AppColorTheme.success : AppColorTheme.brand)
            .withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        isMainDevice ? context.l10n.mainDeviceRole : context.l10n.subDeviceRole,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: isMainDevice ? AppColorTheme.success : AppColorTheme.brand,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _TinyActionButton extends StatelessWidget {
  const _TinyActionButton({
    required this.onPressed,
    required this.icon,
    required this.tooltip,
  });

  final VoidCallback onPressed;
  final IconData icon;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          width: 32,
          height: 32,
          margin: const EdgeInsets.only(left: 6),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Icon(
            icon,
            size: 16,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _NotificationList extends StatelessWidget {
  const _NotificationList({required this.items});

  final List<BankNotificationModel> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 40),
        child: EmptyView(msg: context.l10n.noTrackedNotifications),
      );
    }

    final grouped = <String, List<BankNotificationModel>>{};
    for (final item in items) {
      grouped.putIfAbsent(item.receivedDateLabel, () => []).add(item);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Text(
        //   context.l10n.trackedNotifications,
        //   style: AppTextTheme.title.copyWith(fontSize: 18),
        // ),
        // const SizedBox(height: 12),
        for (final entry in grouped.entries) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              entry.key,
              style: AppTextTheme.title.copyWith(
                fontSize: 16,
              ),
            ),
          ),
          ...entry.value.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _NotificationCard(item: item),
            ),
          ),
          const SizedBox(height: 4),
        ],
      ],
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.item});

  final BankNotificationModel item;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final amountColor =
        item.isIncome ? AppColorTheme.success : AppColorTheme.error;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: colorScheme.surfaceContainerHighest,
                child: Text(
                  item.bankApp.label.characters.first,
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.bankApp.label,
                      style: AppTextTheme.title.copyWith(
                        color: colorScheme.onSurface,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.receivedTimeLabel,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (item.amount != null)
                Text(
                  item.amountLabel,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: amountColor,
                        fontWeight: FontWeight.bold,
                      ),
                ),
            ],
          ),
          if (item.title != null && item.title!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              item.title!,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            item.message,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _MetaChip(
                label: item.isIncome
                    ? context.l10n.incomeOnly
                    : context.l10n.expenseOnly,
                color: amountColor,
              ),
              const SizedBox(width: 8),
              _MetaChip(
                label: item.source.toUpperCase(),
                color: colorScheme.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
