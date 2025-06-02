part of 'dashboard_bloc.dart';

abstract class DashboardEvent extends Equatable {
  const DashboardEvent();

  @override
  List<Object?> get props => [];
}

/// Load dashboard data
class DashboardLoadEvent extends DashboardEvent {
  const DashboardLoadEvent();
}

/// Refresh dashboard data
class DashboardRefreshEvent extends DashboardEvent {
  const DashboardRefreshEvent();
}

/// Driver goes online
class DashboardGoOnlineEvent extends DashboardEvent {
  const DashboardGoOnlineEvent();
}

/// Driver goes offline
class DashboardGoOfflineEvent extends DashboardEvent {
  const DashboardGoOfflineEvent();
} 