part of 'income_bloc.dart';

abstract class IncomeState extends Equatable {
  const IncomeState();

  @override
  List<Object?> get props => [];
}

class IncomeLoading extends IncomeState {
  const IncomeLoading();
}

@CopyWith()
class IncomeLoaded extends IncomeState {
  const IncomeLoaded({
    required this.items,
    this.searchQuery = '',
    this.fromDate,
    this.toDate,
    this.bankFilter,
    this.recordFilter = NotificationRecordFilter.all,
    this.trackingStatus,
  });

  final List<BankNotificationModel> items;
  final String searchQuery;
  final DateTime? fromDate;
  final DateTime? toDate;
  final BankApp? bankFilter;
  final NotificationRecordFilter recordFilter;
  final NotificationTrackingStatus? trackingStatus;

  bool get hasFilter {
    return searchQuery.isNotEmpty ||
        fromDate != null ||
        toDate != null ||
        bankFilter != null ||
        recordFilter != NotificationRecordFilter.all;
  }

  IncomeSummary get summary => IncomeSummary.fromItems(items);

  @override
  List<Object?> get props => [
        items,
        searchQuery,
        fromDate,
        toDate,
        bankFilter,
        recordFilter,
        trackingStatus?.isSupported,
        trackingStatus?.isAccessEnabled,
        trackingStatus?.canCaptureLocally,
        trackingStatus?.isBlockedByAnotherMainDevice,
      ];
}
