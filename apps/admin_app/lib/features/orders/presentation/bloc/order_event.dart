import 'package:equatable/equatable.dart';

abstract class OrderEvent extends Equatable {
  const OrderEvent();

  @override
  List<Object?> get props => [];
}

class LoadOrders extends OrderEvent {
  const LoadOrders();
}

class RefreshOrders extends OrderEvent {
  const RefreshOrders();
}

class LoadOrderDetails extends OrderEvent {
  final String orderId;

  const LoadOrderDetails(this.orderId);

  @override
  List<Object?> get props => [orderId];
}

class UpdateOrderStatus extends OrderEvent {
  final String orderId;
  final String status;

  const UpdateOrderStatus(this.orderId, this.status);

  @override
  List<Object?> get props => [orderId, status];
}

class FilterOrders extends OrderEvent {
  final String? status;
  final String? searchQuery;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? customerId;
  final String? vendorId;
  final String? deliveryAgentId;
  final String? paymentMethod;

  const FilterOrders({
    this.status,
    this.searchQuery,
    this.startDate,
    this.endDate,
    this.customerId,
    this.vendorId,
    this.deliveryAgentId,
    this.paymentMethod,
  });

  @override
  List<Object?> get props => [
        status,
        searchQuery,
        startDate,
        endDate,
        customerId,
        vendorId,
        deliveryAgentId,
        paymentMethod,
      ];
}

class AssignDeliveryAgent extends OrderEvent {
  final String orderId;
  final String deliveryPersonId;

  const AssignDeliveryAgent(this.orderId, this.deliveryPersonId);

  @override
  List<Object?> get props => [orderId, deliveryPersonId];
}

class CancelOrder extends OrderEvent {
  final String orderId;
  final String reason;

  const CancelOrder(this.orderId, this.reason);

  @override
  List<Object?> get props => [orderId, reason];
}

class RefundOrder extends OrderEvent {
  final String orderId;
  final String reason;
  final double? amount;

  const RefundOrder(this.orderId, this.reason, {this.amount});

  @override
  List<Object?> get props => [orderId, reason, amount];
}

class UpdateOrderFees extends OrderEvent {
  final String orderId;
  final double? deliveryFee;
  final double? discount;
  final String? reason;

  const UpdateOrderFees(
    this.orderId, {
    this.deliveryFee,
    this.discount,
    this.reason,
  });

  @override
  List<Object?> get props => [orderId, deliveryFee, discount, reason];
}

