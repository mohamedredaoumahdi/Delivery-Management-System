part of 'dashboard_bloc.dart';

abstract class DashboardState extends Equatable {
  const DashboardState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class DashboardInitial extends DashboardState {
  const DashboardInitial();
}

/// Loading dashboard data
class DashboardLoading extends DashboardState {
  const DashboardLoading();
}

/// Dashboard data loaded successfully
class DashboardLoaded extends DashboardState {
  final DriverStatus driverStatus;
  final DashboardStats todayStats;
  final List<DeliveryOrder> availableDeliveries;
  final List<DeliveryOrder> recentDeliveries;
  final DeliveryOrder? currentDelivery;

  const DashboardLoaded({
    required this.driverStatus,
    required this.todayStats,
    required this.availableDeliveries,
    required this.recentDeliveries,
    this.currentDelivery,
  });

  @override
  List<Object?> get props => [
        driverStatus,
        todayStats,
        availableDeliveries,
        recentDeliveries,
        currentDelivery,
      ];

  DashboardLoaded copyWith({
    DriverStatus? driverStatus,
    DashboardStats? todayStats,
    List<DeliveryOrder>? availableDeliveries,
    List<DeliveryOrder>? recentDeliveries,
    DeliveryOrder? currentDelivery,
  }) {
    return DashboardLoaded(
      driverStatus: driverStatus ?? this.driverStatus,
      todayStats: todayStats ?? this.todayStats,
      availableDeliveries: availableDeliveries ?? this.availableDeliveries,
      recentDeliveries: recentDeliveries ?? this.recentDeliveries,
      currentDelivery: currentDelivery ?? this.currentDelivery,
    );
  }
}

/// Error loading dashboard data
class DashboardError extends DashboardState {
  final String message;

  const DashboardError(this.message);

  @override
  List<Object> get props => [message];
} 