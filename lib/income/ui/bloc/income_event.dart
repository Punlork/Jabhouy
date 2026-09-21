part of 'income_bloc.dart';

sealed class IncomeEvent extends Equatable {
  const IncomeEvent();

  @override
  List<Object?> get props => [];
}

class LoadIncomeDashboard extends IncomeEvent {
  const LoadIncomeDashboard({
    this.searchQuery,
    this.fromDate = _incomeDateUnset,
    this.toDate = _incomeDateUnset,
    this.bankFilter = _incomeBankUnset,
    this.recordFilter = _incomeRecordUnset,
  });

  final String? searchQuery;
  final Object? fromDate;
  final Object? toDate;
  final Object? bankFilter;
  final Object? recordFilter;

  @override
  List<Object?> get props => [
        searchQuery,
        fromDate,
        toDate,
        bankFilter,
        recordFilter,
      ];
}

class RefreshIncomeTrackingStatus extends IncomeEvent {
  const RefreshIncomeTrackingStatus();
}

class OpenNotificationAccessSettings extends IncomeEvent {
  const OpenNotificationAccessSettings();
}

class SeedIncomeDemoData extends IncomeEvent {
  const SeedIncomeDemoData(this.successMessage, this.blockedMessage);

  final String successMessage;
  final String blockedMessage;

  @override
  List<Object?> get props => [successMessage, blockedMessage];
}

class _IncomeUpdated extends IncomeEvent {
  const _IncomeUpdated(this.items);

  final List<BankNotificationModel> items;

  @override
  List<Object?> get props => [items];
}

class _IncomeBootstrapCompleted extends IncomeEvent {
  const _IncomeBootstrapCompleted(this.status);

  final NotificationTrackingStatus status;

  @override
  List<Object?> get props => [status];
}
