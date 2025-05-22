part of 'order_bloc.dart';

abstract class OrderEvent extends Equatable {
  const OrderEvent();

  @override
  List<Object?> get props => [];
}

/// Load user orders (active or past)
class OrderLoadListEvent extends OrderEvent {
  final bool active;

  const OrderLoadListEvent({required this.active});

  @override
  List<Object> get props => [active];
}

/// Load order details by ID
class OrderLoadDetailsEvent extends OrderEvent {
  final String orderId;

  const OrderLoadDetailsEvent(this.orderId);

  @override
  List<Object> get props => [orderId];
}

/// Track an order (real-time updates)
class OrderTrackEvent extends OrderEvent {
  final String orderId;

  const OrderTrackEvent(this.orderId);

  @override
  List<Object> get props => [orderId];
}

/// Cancel an order
class OrderCancelEvent extends OrderEvent {
  final String orderId;
  final String? reason;

  const OrderCancelEvent({
    required this.orderId,
    this.reason,
  });

  @override
  List<Object?> get props => [orderId, reason];
}

/// Reorder an existing order
class OrderReorderEvent extends OrderEvent {
  final String orderId;

  const OrderReorderEvent(this.orderId);

  @override
  List<Object> get props => [orderId];
}

/// Place a new order
class OrderPlaceEvent extends OrderEvent {
  final String shopId;
  final List<OrderItem> items;
  final String deliveryAddress;
  final double deliveryLatitude;
  final double deliveryLongitude;
  final String? deliveryInstructions;
  final PaymentMethod paymentMethod;
  final double tip;

  const OrderPlaceEvent({
    required this.shopId,
    required this.items,
    required this.deliveryAddress,
    required this.deliveryLatitude,
    required this.deliveryLongitude,
    this.deliveryInstructions,
    required this.paymentMethod,
    this.tip = 0.0,
  });

  @override
  List<Object?> get props => [
    shopId,
    items,
    deliveryAddress,
    deliveryLatitude,
    deliveryLongitude,
    deliveryInstructions,
    paymentMethod,
    tip,
  ];
}

/// Update tip for an order
class OrderUpdateTipEvent extends OrderEvent {
  final String orderId;
  final double tip;

  const OrderUpdateTipEvent({
    required this.orderId,
    required this.tip,
  });

  @override
  List<Object> get props => [orderId, tip];
}

/// Refresh the order list
class OrderRefreshListEvent extends OrderEvent {
  const OrderRefreshListEvent();
}

/// Load more orders (pagination)
class OrderLoadMoreEvent extends OrderEvent {
  const OrderLoadMoreEvent();
}

/// Auto-refresh event for tracking (internal)
class OrderAutoRefreshEvent extends OrderEvent {
  final String orderId;

  const OrderAutoRefreshEvent(this.orderId);

  @override
  List<Object> get props => [orderId];
}