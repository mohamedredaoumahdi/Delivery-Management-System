part of 'order_bloc.dart';

abstract class OrderState extends Equatable {
  const OrderState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class OrderInitial extends OrderState {
  const OrderInitial();
}

// Order List States

/// Loading order list
class OrderLoadingList extends OrderState {
  final bool isActiveTab;
  final List<Order>? oldOrders;

  const OrderLoadingList({
    required this.isActiveTab,
    this.oldOrders,
  });

  @override
  List<Object?> get props => [isActiveTab, oldOrders];
}

/// Order list loaded successfully
class OrderListLoaded extends OrderState {
  final List<Order> orders;
  final bool hasMore;
  final int currentPage;
  final bool isActiveTab;

  const OrderListLoaded({
    required this.orders,
    required this.hasMore,
    required this.currentPage,
    required this.isActiveTab,
  });

  @override
  List<Object> get props => [orders, hasMore, currentPage, isActiveTab];
}

/// Loading more orders (pagination)
class OrderLoadingMore extends OrderState {
  final List<Order> orders;
  final int currentPage;
  final bool isActiveTab;

  const OrderLoadingMore({
    required this.orders,
    required this.currentPage,
    required this.isActiveTab,
  });

  @override
  List<Object> get props => [orders, currentPage, isActiveTab];
}

// Order Details States

/// Loading order details
class OrderLoadingDetails extends OrderState {
  const OrderLoadingDetails();
}

/// Order details loaded successfully
class OrderDetailsLoaded extends OrderState {
  final Order order;

  const OrderDetailsLoaded(this.order);

  @override
  List<Object> get props => [order];
}

// Order Tracking States

/// Loading order tracking information
class OrderLoadingTracking extends OrderState {
  const OrderLoadingTracking();
}

/// Order tracking loaded successfully
class OrderTrackingLoaded extends OrderState {
  final Order order;

  const OrderTrackingLoaded(this.order);

  @override
  List<Object> get props => [order];
}

/// Order has been delivered
class OrderDelivered extends OrderState {
  final Order order;

  const OrderDelivered(this.order);

  @override
  List<Object> get props => [order];
}

// Order Action States

/// Placing a new order
class OrderPlacing extends OrderState {
  const OrderPlacing();
}

/// Order placed successfully
class OrderPlaced extends OrderState {
  final Order order;

  const OrderPlaced(this.order);

  @override
  List<Object> get props => [order];
}

/// Cancelling an order
class OrderCancelling extends OrderState {
  const OrderCancelling();
}

/// Order cancelled successfully
class OrderCancelled extends OrderState {
  final Order order;

  const OrderCancelled(this.order);

  @override
  List<Object> get props => [order];
}

/// Reordering an existing order
class OrderReordering extends OrderState {
  const OrderReordering();
}

/// Order reordered successfully
class OrderReordered extends OrderState {
  final Order newOrder;

  const OrderReordered(this.newOrder);

  @override
  List<Object> get props => [newOrder];
}

/// Updating order tip
class OrderUpdatingTip extends OrderState {
  const OrderUpdatingTip();
}

/// Order tip updated successfully
class OrderTipUpdated extends OrderState {
  final Order order;

  const OrderTipUpdated(this.order);

  @override
  List<Object> get props => [order];
}

// Error State

/// Order operation failed
class OrderError extends OrderState {
  final String message;
  final bool isListError;
  final bool isDetailsError;
  final bool isTrackingError;
  final bool isActiveTab;

  const OrderError(
    this.message, {
    this.isListError = false,
    this.isDetailsError = false,
    this.isTrackingError = false,
    this.isActiveTab = true,
  });

  @override
  List<Object> get props => [
    message,
    isListError,
    isDetailsError,
    isTrackingError,
    isActiveTab,
  ];
}