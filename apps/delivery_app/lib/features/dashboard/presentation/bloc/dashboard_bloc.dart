import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:core/core.dart';
import '../../data/dashboard_service.dart';
import '../../../delivery/data/delivery_service.dart';

part 'dashboard_event.dart';
part 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final DashboardService _dashboardService;
  final DeliveryService _deliveryService;
  final LoggerService _logger;

  DashboardBloc(this._dashboardService, this._deliveryService, this._logger) : super(const DashboardInitial()) {
    on<DashboardLoadEvent>(_onLoad);
    on<DashboardRefreshEvent>(_onRefresh);
    on<DashboardGoOnlineEvent>(_onGoOnline);
    on<DashboardGoOfflineEvent>(_onGoOffline);
  }

  Future<void> _onLoad(
    DashboardLoadEvent event,
    Emitter<DashboardState> emit,
  ) async {
    _logger.i('🚀 DashboardBloc: Loading dashboard data');
    emit(const DashboardLoading());

    try {
      // Get stored driver status first
      final storedStatus = _dashboardService.getStoredStatus();
      final driverStatus = storedStatus == 'online' ? DriverStatus.online : DriverStatus.offline;
      _logger.i('🔄 DashboardBloc: Retrieved stored driver status: $storedStatus');

      // Only fetch orders if driver is online
      List<Map<String, dynamic>> ordersData = [];
      if (driverStatus == DriverStatus.online) {
        _logger.i('📡 DashboardBloc: Driver is online, fetching available orders');
        ordersData = await _deliveryService.getAvailableOrders();
        _logger.i('✅ DashboardBloc: Received ${ordersData.length} orders from API');
      } else {
        _logger.i('ℹ️ DashboardBloc: Driver is offline, skipping order fetch');
      }
      
      // Get stats
      final statsData = await _dashboardService.getStats();
      _logger.i('✅ DashboardBloc: Received stats from API');
      
      // Convert API response to DeliveryOrder objects
      final availableDeliveries = ordersData.map((orderData) {
        final customerName = orderData['user']?['name'] ?? 'Unknown Customer';
        final shopName = orderData['shopName'] ?? orderData['shop_name'] ?? 'Unknown Shop';
        final orderNumber = orderData['orderNumber'] ?? orderData['order_number'] ?? '';
        final deliveryAddress = orderData['deliveryAddress'] ?? orderData['delivery_address'] ?? '';
        
        _logger.i('🔄 DashboardBloc: Converting order: ${orderData['id']}');
        _logger.i('   Customer: $customerName');
        _logger.i('   Shop: $shopName');
        _logger.i('   Address: $deliveryAddress');
        _logger.i('   Total: \$${orderData['total']}');
        
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

      _logger.i('📦 DashboardBloc: Converted to ${availableDeliveries.length} DeliveryOrder objects');

      // Get recent deliveries (assigned to this driver)
      _logger.i('📡 DashboardBloc: Fetching recent deliveries');
      final recentOrdersData = await _deliveryService.getAssignedOrders();
      _logger.i('✅ DashboardBloc: Received ${recentOrdersData.length} recent orders');
      
      // Convert to DeliveryOrder objects
      final recentDeliveries = recentOrdersData.map((orderData) {
        final customerName = orderData['user']?['name'] ?? 'Unknown Customer';
        final shopName = orderData['shopName'] ?? orderData['shop_name'] ?? 'Unknown Shop';
        final orderNumber = orderData['orderNumber'] ?? orderData['order_number'] ?? '';
        final deliveryAddress = orderData['deliveryAddress'] ?? orderData['delivery_address'] ?? '';
        final backendStatus = orderData['status'] ?? 'PENDING';
        
        _logger.i('🔄 DashboardBloc: Converting recent order: ${orderData['id']}');
        _logger.i('   Customer: $customerName');
        _logger.i('   Shop: $shopName');
        _logger.i('   Status: $backendStatus');
        
        // Map backend status to delivery status
        final deliveryStatus = _mapBackendStatusToDeliveryStatus(backendStatus);
        
        return DeliveryOrder(
          id: orderData['id'] ?? '',
          orderNumber: orderNumber,
          customerName: customerName,
          deliveryAddress: deliveryAddress,
          total: (orderData['total'] ?? 0).toDouble(),
          distance: 2.0, // TODO: Calculate actual distance
          status: deliveryStatus,
        );
      }).toList();

      _logger.i('📦 DashboardBloc: Converted to ${recentDeliveries.length} recent delivery objects');

      final dashboardData = DashboardLoaded(
        driverStatus: driverStatus,
        todayStats: DashboardStats(
          deliveryCount: statsData['deliveryCount'] ?? 0,
          earnings: (statsData['earnings'] ?? 0).toDouble(),
          onlineMinutes: statsData['onlineMinutes'] ?? 0,
          averageRating: (statsData['rating'] ?? 5.0).toDouble(),
        ),
        availableDeliveries: availableDeliveries,
        recentDeliveries: recentDeliveries, // Now using real data
        currentDelivery: null,
      );

      _logger.i('✅ DashboardBloc: Emitting DashboardLoaded with ${availableDeliveries.length} orders');
      emit(dashboardData);
    } catch (error) {
      _logger.e('❌ DashboardBloc: Error loading dashboard: $error');
      emit(DashboardError(error.toString()));
    }
  }

  Future<void> _onRefresh(
    DashboardRefreshEvent event,
    Emitter<DashboardState> emit,
  ) async {
    _logger.i('🔄 DashboardBloc: Refreshing dashboard data');
    
    try {
      if (state is DashboardLoaded) {
        final currentState = state as DashboardLoaded;
        
        // Get fresh orders from API
        final ordersData = await _deliveryService.getAvailableOrders();
        _logger.i('✅ DashboardBloc: Received ${ordersData.length} orders from API');
        
        // Get fresh recent deliveries (assigned to this driver)
        final recentOrdersData = await _deliveryService.getAssignedOrders();
        _logger.i('✅ DashboardBloc: Received ${recentOrdersData.length} recent orders from API');
        
        // Get fresh stats
        final statsData = await _dashboardService.getStats();
        _logger.i('✅ DashboardBloc: Received fresh stats from API');
        
        // Convert to DeliveryOrder objects
        final availableDeliveries = ordersData.map((orderData) {
          final customerName = orderData['user']?['name'] ?? 'Unknown Customer';
          final shopName = orderData['shopName'] ?? orderData['shop_name'] ?? 'Unknown Shop';
          final orderNumber = orderData['orderNumber'] ?? orderData['order_number'] ?? '';
          final deliveryAddress = orderData['deliveryAddress'] ?? orderData['delivery_address'] ?? '';
          
          return DeliveryOrder(
            id: orderData['id'] ?? '',
            orderNumber: orderNumber,
            customerName: customerName,
            deliveryAddress: deliveryAddress,
            total: (orderData['total'] ?? 0).toDouble(),
            distance: 2.0,
            status: DeliveryStatus.pending,
          );
        }).toList();
        
        // Convert recent deliveries to DeliveryOrder objects
        final recentDeliveries = recentOrdersData.map((orderData) {
          final customerName = orderData['user']?['name'] ?? 'Unknown Customer';
          final shopName = orderData['shopName'] ?? orderData['shop_name'] ?? 'Unknown Shop';
          final orderNumber = orderData['orderNumber'] ?? orderData['order_number'] ?? '';
          final deliveryAddress = orderData['deliveryAddress'] ?? orderData['delivery_address'] ?? '';
          final backendStatus = orderData['status'] ?? 'PENDING';
          
          return DeliveryOrder(
            id: orderData['id'] ?? '',
            orderNumber: orderNumber,
            customerName: customerName,
            deliveryAddress: deliveryAddress,
            total: (orderData['total'] ?? 0).toDouble(),
            distance: 2.0,
            status: _mapBackendStatusToDeliveryStatus(backendStatus),
          );
        }).toList();
        
        // Updated data with fresh orders and stats
        final updatedData = currentState.copyWith(
          availableDeliveries: availableDeliveries,
          recentDeliveries: recentDeliveries,
          todayStats: DashboardStats(
            deliveryCount: statsData['deliveryCount'] ?? 0,
            earnings: (statsData['earnings'] ?? 0).toDouble(),
            onlineMinutes: statsData['onlineMinutes'] ?? 0,
            averageRating: (statsData['rating'] ?? 5.0).toDouble(),
          ),
        );

        _logger.i('✅ DashboardBloc: Emitting refreshed data with ${availableDeliveries.length} available and ${recentDeliveries.length} recent orders');
        emit(updatedData);
      } else {
        _logger.w('⚠️ DashboardBloc: State not loaded, performing full load instead');
        add(const DashboardLoadEvent());
      }
    } catch (error) {
      _logger.e('❌ DashboardBloc: Error refreshing dashboard: $error');
      emit(DashboardError(error.toString()));
    }
  }

  Future<void> _onGoOnline(
    DashboardGoOnlineEvent event,
    Emitter<DashboardState> emit,
  ) async {
    _logger.i('🚀 DashboardBloc: Going online');
    if (state is DashboardLoaded) {
      final currentState = state as DashboardLoaded;
      
      try {
        await _dashboardService.goOnline();
        _logger.i('✅ DashboardBloc: Successfully went online');
        
        emit(currentState.copyWith(driverStatus: DriverStatus.online));
        _logger.i('📊 DashboardBloc: Updated state to online');
        
        // Refresh available orders
        add(const DashboardRefreshEvent());
      } catch (error) {
        _logger.e('❌ DashboardBloc: Error going online: $error');
        emit(DashboardError('Failed to go online: ${error.toString()}'));
      }
    }
  }

  Future<void> _onGoOffline(
    DashboardGoOfflineEvent event,
    Emitter<DashboardState> emit,
  ) async {
    _logger.i('🚀 DashboardBloc: Going offline');
    if (state is DashboardLoaded) {
      final currentState = state as DashboardLoaded;
      
      try {
        await _dashboardService.goOffline();
        _logger.i('✅ DashboardBloc: Successfully went offline');
        
        emit(currentState.copyWith(
          driverStatus: DriverStatus.offline,
          availableDeliveries: [], // Clear available orders when going offline
          currentDelivery: null,
        ));
        _logger.i('📊 DashboardBloc: Updated state to offline and cleared orders');
      } catch (error) {
        _logger.e('❌ DashboardBloc: Error going offline: $error');
        emit(DashboardError('Failed to go offline: ${error.toString()}'));
      }
    }
  }

  /// Maps backend order status to delivery app status
  DeliveryStatus _mapBackendStatusToDeliveryStatus(String backendStatus) {
    switch (backendStatus.toUpperCase()) {
      case 'READY_FOR_PICKUP':
        return DeliveryStatus.readyForPickup; // Order is ready for driver to pick up
      case 'PICKED_UP':
      case 'IN_DELIVERY':
        return DeliveryStatus.pickedUp; // Driver has picked up the order
      case 'ON_THE_WAY':
        return DeliveryStatus.inTransit; // Driver is on the way to customer
      case 'DELIVERED':
        return DeliveryStatus.delivered; // Order has been delivered
      case 'ACCEPTED':
        return DeliveryStatus.accepted; // Driver accepted the order
      default:
        _logger.w('⚠️ DashboardBloc: Unknown backend status: $backendStatus, defaulting to pending');
        return DeliveryStatus.pending;
    }
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

enum DeliveryStatus { pending, readyForPickup, accepted, pickedUp, inTransit, delivered } 