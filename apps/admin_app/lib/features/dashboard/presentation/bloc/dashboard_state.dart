import 'package:equatable/equatable.dart';

import '../../data/models/dashboard_overview_model.dart';

abstract class DashboardState extends Equatable {
  const DashboardState();

  @override
  List<Object?> get props => [];
}

class DashboardInitial extends DashboardState {
  const DashboardInitial();
}

class DashboardLoading extends DashboardState {
  const DashboardLoading();
}

class DashboardLoaded extends DashboardState {
  final DashboardOverview overview;
  final DateTime fetchedAt;

  const DashboardLoaded({
    required this.overview,
    required this.fetchedAt,
  });

  @override
  List<Object?> get props => [overview, fetchedAt];
}

class DashboardError extends DashboardState {
  final String message;

  const DashboardError(this.message);

  @override
  List<Object?> get props => [message];
}
