import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'dart:async';

import '../../../../di/injection_container.dart';

// Events
abstract class AnalyticsEvent extends Equatable {
  const AnalyticsEvent();

  @override
  List<Object?> get props => [];
}

class LoadAnalytics extends AnalyticsEvent {}

class RefreshMetric extends AnalyticsEvent {
  final String metricType; // 'orders', 'revenue', 'rating', etc.
  
  const RefreshMetric(this.metricType);
  
  @override
  List<Object?> get props => [metricType];
}

class StartRealTimeUpdates extends AnalyticsEvent {}

class StopRealTimeUpdates extends AnalyticsEvent {}

class UpdateMetricData extends AnalyticsEvent {
  final String metricType;
  final dynamic value;
  
  const UpdateMetricData(this.metricType, this.value);
  
  @override
  List<Object?> get props => [metricType, value];
}

// States
abstract class AnalyticsState extends Equatable {
  const AnalyticsState();

  @override
  List<Object?> get props => [];
}

class AnalyticsInitial extends AnalyticsState {}

class AnalyticsLoading extends AnalyticsState {}

class AnalyticsLoaded extends AnalyticsState {
  final Map<String, dynamic> analyticsData;
  final DateTime lastUpdated;

  const AnalyticsLoaded({
    required this.analyticsData,
    required this.lastUpdated,
  });

  @override
  List<Object?> get props => [analyticsData, lastUpdated];
  
  // Create a copy with updated data
  AnalyticsLoaded copyWith({
    Map<String, dynamic>? analyticsData,
    DateTime? lastUpdated,
  }) {
    return AnalyticsLoaded(
      analyticsData: analyticsData ?? this.analyticsData,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
  
  // Update specific metric without affecting others
  AnalyticsLoaded updateMetric(String metricType, dynamic value) {
    final updatedData = Map<String, dynamic>.from(analyticsData);
    updatedData[metricType] = value;
    
    return AnalyticsLoaded(
      analyticsData: updatedData,
      lastUpdated: DateTime.now(),
    );
  }
}

class MetricUpdating extends AnalyticsState {
  final Map<String, dynamic> analyticsData;
  final String updatingMetric;
  final DateTime lastUpdated;

  const MetricUpdating({
    required this.analyticsData,
    required this.updatingMetric,
    required this.lastUpdated,
  });

  @override
  List<Object?> get props => [analyticsData, updatingMetric, lastUpdated];
}

class AnalyticsError extends AnalyticsState {
  final String message;

  const AnalyticsError({required this.message});

  @override
  List<Object?> get props => [message];
}

// Bloc
class AnalyticsBloc extends Bloc<AnalyticsEvent, AnalyticsState> {
  final VendorService vendorService;
  final OrderService orderService;
  final MenuService menuService;
  
  Timer? _realTimeTimer;
  static const Duration _updateInterval = Duration(seconds: 30);

  AnalyticsBloc({
    required this.vendorService,
    required this.orderService,
    required this.menuService,
  }) : super(AnalyticsInitial()) {
    on<LoadAnalytics>(_onLoadAnalytics);
    on<RefreshMetric>(_onRefreshMetric);
    on<StartRealTimeUpdates>(_onStartRealTimeUpdates);
    on<StopRealTimeUpdates>(_onStopRealTimeUpdates);
    on<UpdateMetricData>(_onUpdateMetricData);
  }

  @override
  Future<void> close() {
    _realTimeTimer?.cancel();
    return super.close();
  }

  Future<void> _onLoadAnalytics(
    LoadAnalytics event,
    Emitter<AnalyticsState> emit,
  ) async {
    emit(AnalyticsLoading());
    
    try {
      final data = await _loadAllAnalyticsData();
      emit(AnalyticsLoaded(
        analyticsData: data,
        lastUpdated: DateTime.now(),
      ));
      
      // Start real-time updates after initial load
      add(StartRealTimeUpdates());
    } catch (e) {
      emit(AnalyticsError(message: e.toString()));
    }
  }

  Future<void> _onRefreshMetric(
    RefreshMetric event,
    Emitter<AnalyticsState> emit,
  ) async {
    if (state is! AnalyticsLoaded) return;
    
    final currentState = state as AnalyticsLoaded;
    
    emit(MetricUpdating(
      analyticsData: currentState.analyticsData,
      updatingMetric: event.metricType,
      lastUpdated: currentState.lastUpdated,
    ));
    
    try {
      final updatedValue = await _loadSpecificMetric(event.metricType);
      
      emit(currentState.updateMetric(event.metricType, updatedValue));
    } catch (e) {
      // Return to previous state if update fails
      emit(currentState);
    }
  }

  Future<void> _onStartRealTimeUpdates(
    StartRealTimeUpdates event,
    Emitter<AnalyticsState> emit,
  ) async {
    _realTimeTimer?.cancel();
    _realTimeTimer = Timer.periodic(_updateInterval, (timer) {
      if (state is AnalyticsLoaded) {
        _refreshCriticalMetrics();
      }
    });
  }

  Future<void> _onStopRealTimeUpdates(
    StopRealTimeUpdates event,
    Emitter<AnalyticsState> emit,
  ) async {
    _realTimeTimer?.cancel();
  }

  Future<void> _onUpdateMetricData(
    UpdateMetricData event,
    Emitter<AnalyticsState> emit,
  ) async {
    if (state is AnalyticsLoaded) {
      final currentState = state as AnalyticsLoaded;
      emit(currentState.updateMetric(event.metricType, event.value));
    }
  }

  Future<Map<String, dynamic>> _loadAllAnalyticsData() async {
    // Load all analytics data in parallel
    final futures = await Future.wait([
      vendorService.getDashboardData(),
      _getOrderStats(),
      _getMenuStats(),
      vendorService.getAnalytics(),
      vendorService.getProductAnalytics(),
      vendorService.getPerformanceAnalytics(),
    ]);
    
    final dashboardData = futures[0] as Map<String, dynamic>;
    final orderStats = futures[1] as Map<String, dynamic>;
    final menuStats = futures[2] as Map<String, dynamic>;
    final salesAnalytics = futures[3] as Map<String, dynamic>;
    final productAnalytics = futures[4] as List<Map<String, dynamic>>;
    final performanceAnalytics = futures[5] as Map<String, dynamic>;
    
    // Merge all data
    final combinedData = Map<String, dynamic>.from(dashboardData);
    combinedData.addAll(orderStats);
    combinedData.addAll(menuStats);
    
    // Add sales analytics
    if (salesAnalytics['revenueTrend'] != null) {
      combinedData['revenueTrend'] = salesAnalytics['revenueTrend'];
    }
    
    // Add top products
    combinedData['topProducts'] = productAnalytics;
    
    // Add performance analytics
    combinedData.addAll(performanceAnalytics);
    
    return combinedData;
  }

  Future<dynamic> _loadSpecificMetric(String metricType) async {
    switch (metricType) {
      case 'orders':
        final stats = await _getOrderStats();
        return {
          'todayOrders': stats['todayOrders'],
          'pendingOrders': stats['pendingOrders'],
          'preparingOrders': stats['preparingOrders'],
          'readyOrders': stats['readyOrders'],
          'completedOrders': stats['completedOrders'],
        };
      case 'revenue':
        final data = await vendorService.getDashboardData();
        return {
          'todayRevenue': data['todayRevenue'],
          'weekRevenue': data['weekRevenue'],
          'monthRevenue': data['monthRevenue'],
          'totalRevenue': data['totalRevenue'],
        };
      case 'menu':
        return await _getMenuStats();
      case 'rating':
        final data = await vendorService.getDashboardData();
        return {
          'rating': data['rating'],
          'ratingCount': data['ratingCount'],
        };
      default:
        return await vendorService.getDashboardData();
    }
  }

  Future<Map<String, dynamic>> _getOrderStats() async {
    try {
      final allOrders = await orderService.getOrders();
      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);
      
      final todayOrders = allOrders.where((order) {
        final orderDate = DateTime.parse(order['createdAt'] ?? '');
        return orderDate.isAfter(todayStart);
      }).toList();
      
      final pendingOrders = allOrders.where((order) => 
        order['status'] == 'PENDING' || order['status'] == 'pending').length;
      final preparingOrders = allOrders.where((order) => 
        order['status'] == 'PREPARING' || order['status'] == 'preparing').length;
      final readyOrders = allOrders.where((order) => 
        order['status'] == 'READY' || order['status'] == 'ready').length;
      final completedOrders = todayOrders.where((order) => 
        order['status'] == 'COMPLETED' || order['status'] == 'completed').length;
      
      return {
        'todayOrders': todayOrders.length,
        'pendingOrders': pendingOrders,
        'preparingOrders': preparingOrders,
        'readyOrders': readyOrders,
        'completedOrders': completedOrders,
      };
    } catch (e) {
      return {
        'todayOrders': 0,
        'pendingOrders': 0,
        'preparingOrders': 0,
        'readyOrders': 0,
        'completedOrders': 0,
      };
    }
  }

  Future<Map<String, dynamic>> _getMenuStats() async {
    try {
      final menuItems = await menuService.getMenuItems();
      final activeItems = menuItems.where((item) => 
        item['isAvailable'] == true || item['isActive'] == true || item['inStock'] == true).length;
      final outOfStockItems = menuItems.where((item) => 
        item['isAvailable'] == false || item['isActive'] == false || item['inStock'] == false).length;
      
      return {
        'activeMenuItems': activeItems,
        'outOfStockItems': outOfStockItems,
        'totalMenuItems': menuItems.length,
      };
    } catch (e) {
      return {
        'activeMenuItems': 0,
        'outOfStockItems': 0,
        'totalMenuItems': 0,
      };
    }
  }

  void _refreshCriticalMetrics() {
    // Refresh the most important metrics that change frequently
    add(const RefreshMetric('orders'));
    
    // Stagger the updates to avoid overwhelming the backend
    Future.delayed(const Duration(seconds: 5), () {
      add(const RefreshMetric('menu'));
    });
    
    Future.delayed(const Duration(seconds: 10), () {
      add(const RefreshMetric('revenue'));
    });
  }
} 