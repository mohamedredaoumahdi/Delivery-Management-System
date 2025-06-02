import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';

part 'dashboard_event.dart';
part 'dashboard_state.dart';

@injectable
class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  DashboardBloc() : super(const DashboardInitial()) {
    on<DashboardLoadEvent>(_onLoad);
    on<DashboardRefreshEvent>(_onRefresh);
    on<DashboardGoOnlineEvent>(_onGoOnline);
    on<DashboardGoOfflineEvent>(_onGoOffline);
  }

  Future<void> _onLoad(
    DashboardLoadEvent event,
    Emitter<DashboardState> emit,
  ) async {
    emit(const DashboardLoading());

    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));

      // Mock data - in real app, this would come from repositories
      final mockData = DashboardLoaded(
        driverStatus: DriverStatus.offline,
        todayStats: const DashboardStats(
          deliveryCount: 0,
          earnings: 0.0,
          onlineMinutes: 0,
          averageRating: 5.0,
        ),
        availableDeliveries: _getMockAvailableDeliveries(),
        recentDeliveries: _getMockRecentDeliveries(),
        currentDelivery: null,
      );

      emit(mockData);
    } catch (error) {
      emit(DashboardError(error.toString()));
    }
  }

  Future<void> _onRefresh(
    DashboardRefreshEvent event,
    Emitter<DashboardState> emit,
  ) async {
    // Don't show loading for refresh
    try {
      // Simulate API call
      await Future.delayed(const Duration(milliseconds: 500));

      // Get current state
      if (state is DashboardLoaded) {
        final currentState = state as DashboardLoaded;
        
        // Mock updated data
        final updatedData = currentState.copyWith(
          availableDeliveries: _getMockAvailableDeliveries(),
          recentDeliveries: _getMockRecentDeliveries(),
        );

        emit(updatedData);
      } else {
        // If not loaded, perform full load
        add(const DashboardLoadEvent());
      }
    } catch (error) {
      emit(DashboardError(error.toString()));
    }
  }

  Future<void> _onGoOnline(
    DashboardGoOnlineEvent event,
    Emitter<DashboardState> emit,
  ) async {
    if (state is DashboardLoaded) {
      final currentState = state as DashboardLoaded;
      
      try {
        // Simulate API call to go online
        await Future.delayed(const Duration(milliseconds: 500));
        
        emit(currentState.copyWith(driverStatus: DriverStatus.online));
      } catch (error) {
        emit(DashboardError('Failed to go online: ${error.toString()}'));
      }
    }
  }

  Future<void> _onGoOffline(
    DashboardGoOfflineEvent event,
    Emitter<DashboardState> emit,
  ) async {
    if (state is DashboardLoaded) {
      final currentState = state as DashboardLoaded;
      
      try {
        // Simulate API call to go offline
        await Future.delayed(const Duration(milliseconds: 500));
        
        emit(currentState.copyWith(
          driverStatus: DriverStatus.offline,
          currentDelivery: null, // Clear current delivery when going offline
        ));
      } catch (error) {
        emit(DashboardError('Failed to go offline: ${error.toString()}'));
      }
    }
  }

  // Mock data generators
  List<DeliveryOrder> _getMockAvailableDeliveries() {
    return [
      const DeliveryOrder(
        id: '1',
        orderNumber: 'ORD-001',
        customerName: 'John Doe',
        deliveryAddress: '123 Main St, Downtown',
        total: 24.99,
        distance: 2.3,
        status: DeliveryStatus.pending,
      ),
      const DeliveryOrder(
        id: '2',
        orderNumber: 'ORD-002',
        customerName: 'Jane Smith',
        deliveryAddress: '456 Oak Ave, Midtown',
        total: 18.50,
        distance: 1.8,
        status: DeliveryStatus.pending,
      ),
      const DeliveryOrder(
        id: '3',
        orderNumber: 'ORD-003',
        customerName: 'Mike Wilson',
        deliveryAddress: '789 Pine Rd, Uptown',
        total: 32.75,
        distance: 3.1,
        status: DeliveryStatus.pending,
      ),
    ];
  }

  List<DeliveryOrder> _getMockRecentDeliveries() {
    return [
      DeliveryOrder(
        id: '101',
        orderNumber: 'ORD-098',
        customerName: 'Sarah Johnson',
        deliveryAddress: '321 Elm St, Downtown',
        total: 28.99,
        distance: 2.1,
        status: DeliveryStatus.delivered,
        deliveredAt: DateTime.now().subtract(const Duration(hours: 1)),
      ),
      DeliveryOrder(
        id: '102',
        orderNumber: 'ORD-097',
        customerName: 'Robert Brown',
        deliveryAddress: '654 Maple Dr, Suburb',
        total: 22.50,
        distance: 4.2,
        status: DeliveryStatus.delivered,
        deliveredAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
    ];
  }
}

// Data models (these would normally be in the domain layer)
enum DriverStatus { offline, online, busy }

class DashboardStats {
  final int deliveryCount;
  final double earnings;
  final int onlineMinutes;
  final double averageRating;

  const DashboardStats({
    required this.deliveryCount,
    required this.earnings,
    required this.onlineMinutes,
    required this.averageRating,
  });

  DashboardStats copyWith({
    int? deliveryCount,
    double? earnings,
    int? onlineMinutes,
    double? averageRating,
  }) {
    return DashboardStats(
      deliveryCount: deliveryCount ?? this.deliveryCount,
      earnings: earnings ?? this.earnings,
      onlineMinutes: onlineMinutes ?? this.onlineMinutes,
      averageRating: averageRating ?? this.averageRating,
    );
  }
}

class DeliveryOrder {
  final String id;
  final String orderNumber;
  final String customerName;
  final String deliveryAddress;
  final double total;
  final double distance;
  final DeliveryStatus status;
  final DateTime? deliveredAt;

  const DeliveryOrder({
    required this.id,
    required this.orderNumber,
    required this.customerName,
    required this.deliveryAddress,
    required this.total,
    required this.distance,
    required this.status,
    this.deliveredAt,
  });

  DeliveryOrder copyWith({
    String? id,
    String? orderNumber,
    String? customerName,
    String? deliveryAddress,
    double? total,
    double? distance,
    DeliveryStatus? status,
    DateTime? deliveredAt,
  }) {
    return DeliveryOrder(
      id: id ?? this.id,
      orderNumber: orderNumber ?? this.orderNumber,
      customerName: customerName ?? this.customerName,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      total: total ?? this.total,
      distance: distance ?? this.distance,
      status: status ?? this.status,
      deliveredAt: deliveredAt ?? this.deliveredAt,
    );
  }
}

enum DeliveryStatus { pending, accepted, pickedUp, inTransit, delivered } 