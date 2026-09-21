part of 'income_bloc.dart';

abstract class IncomeState extends Equatable {
  const IncomeState();

  @override
  List<Object?> get props => [];
}

class IncomeLoading extends IncomeState {
  const IncomeLoading();
}

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

  IncomeLoaded copyWith({
    List<BankNotificationModel>? items,
    String? searchQuery,
    Object? fromDate = _incomeDateUnset,
    Object? toDate = _incomeDateUnset,
    Object? bankFilter = _incomeBankUnset,
    Object? recordFilter = _incomeRecordUnset,
    Object? trackingStatus = _incomeStatusUnset,
  }) {
    return IncomeLoaded(
      items: items ?? this.items,
      searchQuery: searchQuery ?? this.searchQuery,
      fromDate: identical(fromDate, _incomeDateUnset)
          ? this.fromDate
          : fromDate as DateTime?,
      toDate: identical(toDate, _incomeDateUnset)
          ? this.toDate
          : toDate as DateTime?,
      bankFilter: identical(bankFilter, _incomeBankUnset)
          ? this.bankFilter
          : bankFilter as BankApp?,
      recordFilter: identical(recordFilter, _incomeRecordUnset)
          ? this.recordFilter
          : recordFilter as NotificationRecordFilter? ??
              NotificationRecordFilter.all,
      trackingStatus: identical(trackingStatus, _incomeStatusUnset)
          ? this.trackingStatus
          : trackingStatus as NotificationTrackingStatus?,
    );
  }

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
