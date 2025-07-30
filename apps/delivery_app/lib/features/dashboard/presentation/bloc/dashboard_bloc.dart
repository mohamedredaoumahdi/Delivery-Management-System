import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import '../../../delivery/data/delivery_service.dart';

part 'dashboard_event.dart';
part 'dashboard_state.dart';


class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final DeliveryService _deliveryService;

  DashboardBloc(this._deliveryService) : super(const DashboardInitial()) {
    on<DashboardLoadEvent>(_onLoad);
    on<DashboardRefreshEvent>(_onRefresh);
    on<DashboardGoOnlineEvent>(_onGoOnline);
    on<DashboardGoOfflineEvent>(_onGoOffline);
  }

  Future<void> _onLoad(
    DashboardLoadEvent event,
    Emitter<DashboardState> emit,
  ) async {
    print('🚀 DashboardBloc: Loading dashboard data');
    emit(const DashboardLoading());

    try {
      print('📡 DashboardBloc: Fetching available orders from API');
      
      // Get real available orders from backend
      final ordersData = await _deliveryService.getAvailableOrders();
      
      print('✅ DashboardBloc: Received ${ordersData.length} orders from API');
      
      // Convert API response to DeliveryOrder objects
      final availableDeliveries = ordersData.map((orderData) {
        final customerName = orderData['user']?['name'] ?? 'Unknown Customer';
        final shopName = orderData['shopName'] ?? orderData['shop_name'] ?? 'Unknown Shop';
        final orderNumber = orderData['orderNumber'] ?? orderData['order_number'] ?? '';
        final deliveryAddress = orderData['deliveryAddress'] ?? orderData['delivery_address'] ?? '';
        
        print('🔄 DashboardBloc: Converting order: ${orderData['id']}');
        print('   Customer: $customerName');
        print('   Shop: $shopName');
        print('   Address: $deliveryAddress');
        print('   Total: \$${orderData['total']}');
        
        return DeliveryOrder(
          id: orderData['id'] ?? '',
          orderNumber: orderNumber,
          customerName: customerName,
          deliveryAddress: deliveryAddress,
          total: (orderData['total'] ?? 0).toDouble(),
          distance: 2.0, // TODO: Calculate actual distance
          status: DeliveryStatus.pending,
        );
      }).toList();

      print('📦 DashboardBloc: Converted to ${availableDeliveries.length} DeliveryOrder objects');

      final dashboardData = DashboardLoaded(
        driverStatus: DriverStatus.offline,
        todayStats: const DashboardStats(
          deliveryCount: 0,
          earnings: 0.0,
          onlineMinutes: 0,
          averageRating: 5.0,
        ),
        availableDeliveries: availableDeliveries,
        recentDeliveries: [], // Empty for now - can be implemented later
        currentDelivery: null,
      );

      print('✅ DashboardBloc: Emitting DashboardLoaded with ${availableDeliveries.length} orders');
      emit(dashboardData);
    } catch (error) {
      print('❌ DashboardBloc: Error loading dashboard: $error');
      emit(DashboardError(error.toString()));
    }
  }

  Future<void> _onRefresh(
    DashboardRefreshEvent event,
    Emitter<DashboardState> emit,
  ) async {
    print('🔄 DashboardBloc: Refreshing dashboard data');
    
    // Don't show loading for refresh
    try {
      print('📡 DashboardBloc: Fetching fresh orders from API');
      
      // Get fresh available orders from backend
      final ordersData = await _deliveryService.getAvailableOrders();
      
      print('✅ DashboardBloc: Received ${ordersData.length} fresh orders');

      // Convert API response to DeliveryOrder objects
      final availableDeliveries = ordersData.map((orderData) {
        final customerName = orderData['user']?['name'] ?? 'Unknown Customer';
        final orderNumber = orderData['orderNumber'] ?? orderData['order_number'] ?? '';
        final deliveryAddress = orderData['deliveryAddress'] ?? orderData['delivery_address'] ?? '';
        
        return DeliveryOrder(
          id: orderData['id'] ?? '',
          orderNumber: orderNumber,
          customerName: customerName,
          deliveryAddress: deliveryAddress,
          total: (orderData['total'] ?? 0).toDouble(),
          distance: 2.0, // TODO: Calculate actual distance
          status: DeliveryStatus.pending,
        );
      }).toList();

      // Get current state
      if (state is DashboardLoaded) {
        final currentState = state as DashboardLoaded;
        
        // Updated data with fresh orders
        final updatedData = currentState.copyWith(
          availableDeliveries: availableDeliveries,
          recentDeliveries: [], // Keep empty for now
        );

        print('✅ DashboardBloc: Emitting refreshed data with ${availableDeliveries.length} orders');
        emit(updatedData);
      } else {
        // If not loaded, perform full load
        print('⚠️ DashboardBloc: State not loaded, performing full load instead');
        add(const DashboardLoadEvent());
      }
    } catch (error) {
      print('❌ DashboardBloc: Error refreshing dashboard: $error');
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

  // Mock data generators removed - now using real API data
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