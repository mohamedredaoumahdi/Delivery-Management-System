import 'package:dartz/dartz.dart' as dartz;

import '../entities/order.dart';
import '../errors/failures.dart';

/// Repository for order operations
abstract class OrderRepository {
  /// Place a new order
  Future<dartz.Either<Failure, Order>> placeOrder({
    required String shopId,
    required List<OrderItem> items,
    required String deliveryAddress,
    required double deliveryLatitude,
    required double deliveryLongitude,
    String? deliveryInstructions,
    required PaymentMethod paymentMethod,
    double tip = 0,
  });
  
  /// Get user orders
  /// [status] is an optional status filter
  /// [page] is the page number (starting from 1)
  /// [limit] is the number of items per page
  Future<dartz.Either<Failure, List<Order>>> getUserOrders({
    OrderStatus? status,
    int page = 1,
    int limit = 20,
  });
  
  /// Get order by ID
  Future<dartz.Either<Failure, Order>> getOrderById(String id);
  
  /// Cancel an order
  Future<dartz.Either<Failure, Order>> cancelOrder(String id, {String? reason});
  
  /// Update tip amount
  Future<dartz.Either<Failure, Order>> updateTip(String id, double tip);
  
  /// For Vendor: Get shop orders
  Future<dartz.Either<Failure, List<Order>>> getShopOrders({
    required String shopId,
    OrderStatus? status,
    int page = 1,
    int limit = 20,
  });
  
  /// For Vendor: Update order status
  Future<dartz.Either<Failure, Order>> updateOrderStatus({
    required String orderId,
    required OrderStatus status,
    String? rejectionReason,
    DateTime? estimatedDeliveryTime,
  });
  
  /// For Delivery: Get assigned orders
  Future<dartz.Either<Failure, List<Order>>> getAssignedOrders({
    OrderStatus? status,
    int page = 1,
    int limit = 20,
  });
  
  /// For Delivery: Update order location
  Future<dartz.Either<Failure, Order>> updateOrderLocation({
    required String orderId,
    required double latitude,
    required double longitude,
  });
  
  /// For Delivery: Mark order as delivered
  Future<dartz.Either<Failure, Order>> markOrderAsDelivered(String orderId);
  
  /// For Admin: Get all orders
  Future<dartz.Either<Failure, List<Order>>> getAllOrders({
    String? userId,
    String? shopId,
    String? deliveryPersonId,
    OrderStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    int page = 1,
    int limit = 20,
  });
  
  /// For Admin: Assign order to delivery person
  Future<dartz.Either<Failure, Order>> assignOrderToDeliveryPerson({
    required String orderId,
    required String deliveryPersonId,
  });
}