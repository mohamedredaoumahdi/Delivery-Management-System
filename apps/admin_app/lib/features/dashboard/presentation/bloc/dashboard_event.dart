import 'package:equatable/equatable.dart';

abstract class DashboardEvent extends Equatable {
  const DashboardEvent();

  @override
  List<Object?> get props => [];
}

class LoadDashboardStatistics extends DashboardEvent {
  const LoadDashboardStatistics();
}

class RefreshDashboardStatistics extends DashboardEvent {
  const RefreshDashboardStatistics();
}

