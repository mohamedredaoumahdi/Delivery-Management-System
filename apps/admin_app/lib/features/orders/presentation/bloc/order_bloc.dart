import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/order_service.dart';
import '../../data/models/order_model.dart';
import 'order_event.dart';
import 'order_state.dart';

class OrderBloc extends Bloc<OrderEvent, OrderState> {
  final OrderService orderService;

  OrderBloc({required this.orderService}) : super(const OrderInitial()) {
    on<LoadOrders>(_onLoadOrders);
    on<RefreshOrders>(_onRefreshOrders);
    on<LoadOrderDetails>(_onLoadOrderDetails);
    on<UpdateOrderStatus>(_onUpdateOrderStatus);
    on<FilterOrders>(_onFilterOrders);
    on<AssignDeliveryAgent>(_onAssignDeliveryAgent);
    on<CancelOrder>(_onCancelOrder);
    on<RefundOrder>(_onRefundOrder);
    on<UpdateOrderFees>(_onUpdateOrderFees);
  }

  Future<void> _onLoadOrders(LoadOrders event, Emitter<OrderState> emit) async {
    emit(const OrderLoading());
    try {
      final orders = await orderService.getOrders();
      emit(OrdersLoaded(
        orders: orders,
        filteredOrders: orders,
        selectedStatus: null,
        searchQuery: null,
      ));
    } catch (e) {
      emit(OrderError(e.toString()));
    }
  }

  Future<void> _onRefreshOrders(RefreshOrders event, Emitter<OrderState> emit) async {
    try {
      final orders = await orderService.getOrders();
      if (state is OrdersLoaded) {
        final currentState = state as OrdersLoaded;
        final filteredOrders = _applyFilters(
          orders,
          status: currentState.selectedStatus,
          searchQuery: currentState.searchQuery,
        );
        emit(OrdersLoaded(
          orders: orders,
          filteredOrders: filteredOrders,
          selectedStatus: currentState.selectedStatus,
          searchQuery: currentState.searchQuery,
        ));
      } else {
        emit(OrdersLoaded(
          orders: orders,
          filteredOrders: orders,
          selectedStatus: null,
          searchQuery: null,
        ));
      }
    } catch (e) {
      emit(OrderError(e.toString()));
    }
  }

  Future<void> _onLoadOrderDetails(LoadOrderDetails event, Emitter<OrderState> emit) async {
    emit(const OrderLoading());
    try {
      final order = await orderService.getOrderById(event.orderId);
      emit(OrderDetailsLoaded(order));
    } catch (e) {
      emit(OrderError(e.toString()));
    }
  }

  Future<void> _onUpdateOrderStatus(UpdateOrderStatus event, Emitter<OrderState> emit) async {
    try {
      final updatedOrder = await orderService.updateOrderStatus(event.orderId, event.status);
      emit(OrderUpdated(updatedOrder));
      
      // Reload orders list and preserve filters
      final orders = await orderService.getOrders();
      if (state is OrdersLoaded) {
        final currentState = state as OrdersLoaded;
        final filteredOrders = _applyFilters(
          orders,
          status: currentState.selectedStatus,
          searchQuery: currentState.searchQuery,
        );
        emit(OrdersLoaded(
          orders: orders,
          filteredOrders: filteredOrders,
          selectedStatus: currentState.selectedStatus,
          searchQuery: currentState.searchQuery,
        ));
      } else {
        emit(OrdersLoaded(
          orders: orders,
          filteredOrders: orders,
          selectedStatus: null,
          searchQuery: null,
        ));
      }
    } catch (e) {
      emit(OrderError(e.toString()));
    }
  }

  void _onFilterOrders(FilterOrders event, Emitter<OrderState> emit) {
    if (state is OrdersLoaded) {
      final currentState = state as OrdersLoaded;
      
      // Apply filters to the original orders list
      final filteredOrders = _applyFilters(
        currentState.orders,
        status: event.status ?? currentState.selectedStatus,
        searchQuery: event.searchQuery ?? currentState.searchQuery,
        startDate: event.startDate,
        endDate: event.endDate,
        customerId: event.customerId,
        vendorId: event.vendorId,
        deliveryAgentId: event.deliveryAgentId,
        paymentMethod: event.paymentMethod,
      );
      
      emit(OrdersLoaded(
        orders: currentState.orders,
        filteredOrders: filteredOrders,
        selectedStatus: event.status ?? currentState.selectedStatus,
        searchQuery: event.searchQuery ?? currentState.searchQuery,
      ));
    }
  }

  Future<void> _onAssignDeliveryAgent(AssignDeliveryAgent event, Emitter<OrderState> emit) async {
    try {
      final updatedOrder = await orderService.assignDeliveryAgent(event.orderId, event.deliveryPersonId);
      emit(OrderUpdated(updatedOrder));
      add(const RefreshOrders());
    } catch (e) {
      emit(OrderError(e.toString()));
    }
  }

  Future<void> _onCancelOrder(CancelOrder event, Emitter<OrderState> emit) async {
    try {
      final updatedOrder = await orderService.cancelOrder(event.orderId, event.reason);
      emit(OrderUpdated(updatedOrder));
      add(const RefreshOrders());
    } catch (e) {
      emit(OrderError(e.toString()));
    }
  }

  Future<void> _onRefundOrder(RefundOrder event, Emitter<OrderState> emit) async {
    try {
      final result = await orderService.refundOrder(event.orderId, event.reason, amount: event.amount);
      emit(OrderUpdated(result['order'] as OrderModel));
      add(const RefreshOrders());
    } catch (e) {
      emit(OrderError(e.toString()));
    }
  }

  Future<void> _onUpdateOrderFees(UpdateOrderFees event, Emitter<OrderState> emit) async {
    try {
      final updatedOrder = await orderService.updateOrderFees(
        event.orderId,
        deliveryFee: event.deliveryFee,
        discount: event.discount,
        reason: event.reason,
      );
      emit(OrderUpdated(updatedOrder));
      add(const RefreshOrders());
    } catch (e) {
      emit(OrderError(e.toString()));
    }
  }

  List<OrderModel> _applyFilters(
    List<OrderModel> orders, {
    String? status,
    String? searchQuery,
    DateTime? startDate,
    DateTime? endDate,
    String? customerId,
    String? vendorId,
    String? deliveryAgentId,
    String? paymentMethod,
  }) {
    var filtered = List<OrderModel>.from(orders);

    // Apply status filter
    if (status != null && status.isNotEmpty) {
      filtered = filtered.where((order) => order.status == status).toList();
    }

    // Apply date range filter
    if (startDate != null) {
      filtered = filtered.where((order) => order.createdAt.isAfter(startDate) || order.createdAt.isAtSameMomentAs(startDate)).toList();
    }
    if (endDate != null) {
      final endOfDay = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
      filtered = filtered.where((order) => order.createdAt.isBefore(endOfDay) || order.createdAt.isAtSameMomentAs(endOfDay)).toList();
    }

    // Apply customer filter
    if (customerId != null && customerId.isNotEmpty) {
      filtered = filtered.where((order) => order.userId == customerId).toList();
    }

    // Apply vendor filter
    if (vendorId != null && vendorId.isNotEmpty) {
      filtered = filtered.where((order) => order.shopId == vendorId).toList();
    }

    // Apply delivery agent filter
    if (deliveryAgentId != null && deliveryAgentId.isNotEmpty) {
      filtered = filtered.where((order) => order.deliveryPersonId == deliveryAgentId).toList();
    }

    // Apply payment method filter
    if (paymentMethod != null && paymentMethod.isNotEmpty) {
      filtered = filtered.where((order) => order.paymentMethod == paymentMethod).toList();
    }

    // Apply search query
    if (searchQuery != null && searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase().trim();
      filtered = filtered.where((order) {
        // Search in order number
        final orderNumber = order.orderNumber.toLowerCase();
        if (orderNumber.contains(query)) return true;
        
        // Search in customer name
        if (order.user != null) {
          final customerName = (order.user!['name']?.toString() ?? '').toLowerCase();
          if (customerName.contains(query)) return true;
        }
        
        // Search in shop name
        final shopName = (order.shop?['name']?.toString() ?? order.shopName).toLowerCase();
        if (shopName.contains(query)) return true;
        
        // Search in delivery address
        final address = order.deliveryAddress.toLowerCase();
        if (address.contains(query)) return true;
        
        return false;
      }).toList();
    }

    return filtered;
  }
}

