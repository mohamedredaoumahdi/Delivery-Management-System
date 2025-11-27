import 'package:equatable/equatable.dart';
import '../../data/models/order_model.dart';

abstract class OrderState extends Equatable {
  const OrderState();

  @override
  List<Object?> get props => [];
}

class OrderInitial extends OrderState {
  const OrderInitial();
}

class OrderLoading extends OrderState {
  const OrderLoading();
}

class OrdersLoaded extends OrderState {
  final List<OrderModel> orders;
  final List<OrderModel> filteredOrders;
  final String? selectedStatus;
  final String? searchQuery;

  const OrdersLoaded({
    required this.orders,
    required this.filteredOrders,
    this.selectedStatus,
    this.searchQuery,
  });

  @override
  List<Object?> get props => [orders, filteredOrders, selectedStatus, searchQuery];

  OrdersLoaded copyWith({
    List<OrderModel>? orders,
    List<OrderModel>? filteredOrders,
    String? selectedStatus,
    String? searchQuery,
  }) {
    return OrdersLoaded(
      orders: orders ?? this.orders,
      filteredOrders: filteredOrders ?? this.filteredOrders,
      selectedStatus: selectedStatus ?? this.selectedStatus,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class OrderDetailsLoaded extends OrderState {
  final OrderModel order;

  const OrderDetailsLoaded(this.order);

  @override
  List<Object?> get props => [order];
}

class OrderError extends OrderState {
  final String message;

  const OrderError(this.message);

  @override
  List<Object?> get props => [message];
}

class OrderUpdated extends OrderState {
  final OrderModel order;

  const OrderUpdated(this.order);

  @override
  List<Object?> get props => [order];
}

