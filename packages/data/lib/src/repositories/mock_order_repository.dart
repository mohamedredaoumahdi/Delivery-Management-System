import 'package:dartz/dartz.dart' hide Order;
import 'package:domain/domain.dart';

class MockOrderRepository implements OrderRepository {
  // Mock data
  final List<Order> _mockOrders = [
    // Add some mock Order objects here
    // Example:
    Order(
      id: 'order1',
      userId: 'mock_user_1',
      shopId: 'shop1',
      shopName: 'Mock Pizza Place',
      items: [
        OrderItem(
          productId: 'prod1',
          productName: 'Margherita Pizza',
          productPrice: 12.99,
          quantity: 1,
          totalPrice: 12.99,
          instructions: null,
        ),
      ],
      deliveryAddress: '123 Mock St',
      deliveryLatitude: 0.0,
      deliveryLongitude: 0.0,
      subtotal: 12.99,
      deliveryFee: 2.0,
      serviceFee: 0.50,
      tax: 1.00,
      tip: 0.0,
      discount: 0.0,
      total: 16.49,
      paymentMethod: PaymentMethod.cashOnDelivery,
      status: OrderStatus.pending,
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      updatedAt: DateTime.now(),
    ),
     Order(
      id: 'order2',
      userId: 'mock_user_1',
      shopId: 'shop2',
      shopName: 'Mock Coffee Shop',
      items: [
        OrderItem(
          productId: 'prod3',
          productName: 'Cappuccino',
          productPrice: 3.99,
          quantity: 2,
          totalPrice: 7.98,
          instructions: null,
        ),
         OrderItem(
          productId: 'prod4',
          productName: 'Blueberry Muffin',
          productPrice: 2.49,
          quantity: 1,
          totalPrice: 2.49,
          instructions: null,
        ),
      ],
      deliveryAddress: '123 Mock St',
      deliveryLatitude: 0.0,
      deliveryLongitude: 0.0,
      subtotal: 10.47, // (2*3.99) + 2.49
      deliveryFee: 0.0,
      serviceFee: 0.30,
      tax: 0.70,
      tip: 0.0,
      discount: 0.0,
      total: 11.47,
      paymentMethod: PaymentMethod.card,
      status: OrderStatus.delivered,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      updatedAt: DateTime.now(),
    ),
  ];

  @override
  Future<Either<Failure, Order>> placeOrder({
    required String shopId,
    required List<OrderItem> items,
    required String deliveryAddress,
    required double deliveryLatitude,
    required double deliveryLongitude,
    String? deliveryInstructions,
    required PaymentMethod paymentMethod,
    double tip = 0,
  }) async {
    // Simulate placing an order - create a new mock order
    await Future.delayed(const Duration(milliseconds: 100));
    // Hardcode shop name for mock order creation
    String shopName = 'Unknown Shop';
    if (shopId == 'shop1') shopName = 'Mock Pizza Place';
    if (shopId == 'shop2') shopName = 'Mock Coffee Shop';

    final newOrder = Order(
      id: 'order${_mockOrders.length + 1}',
      userId: 'mock_user_1', // Assuming a mock user is always signed in
      shopId: shopId,
      shopName: shopName,
      items: items,
      subtotal: items.fold(0.0, (sum, item) => sum + (item.productPrice * item.quantity)),
      deliveryFee: 0.0,
      serviceFee: 0.0,
      tax: 0.0,
      tip: tip,
      discount: 0.0,
      total: items.fold(0.0, (sum, item) => sum + (item.productPrice * item.quantity)) + tip,
      paymentMethod: paymentMethod,
      status: OrderStatus.pending,
      deliveryAddress: deliveryAddress,
      deliveryLatitude: deliveryLatitude,
      deliveryLongitude: deliveryLongitude,
      deliveryInstructions: deliveryInstructions,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _mockOrders.add(newOrder);
    return Right(newOrder);
  }

  @override
  Future<Either<Failure, List<Order>>> getUserOrders({
    OrderStatus? status,
    int page = 1,
    int limit = 20,
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));
    var orders = _mockOrders.where((order) => order.userId == 'mock_user_1').toList();
    if (status != null) {
      orders = orders.where((order) => order.status == status).toList();
    }
    final startIndex = (page - 1) * limit;
    final endIndex = startIndex + limit;
    orders = orders.sublist(startIndex, endIndex.clamp(0, orders.length));
    return Right(orders);
  }

  @override
  Future<Either<Failure, Order>> getOrderById(String id) async {
     await Future.delayed(const Duration(milliseconds: 100));
     try {
       final order = _mockOrders.firstWhere((order) => order.id == id);
       return Right(order);
     } catch (e) {
       return Left(UnknownFailure('Order not found'));
     }
  }

  @override
  Future<Either<Failure, Order>> cancelOrder(String id, {String? reason}) async {
     await Future.delayed(const Duration(milliseconds: 100));
     try {
       final order = _mockOrders.firstWhere((order) => order.id == id);
        if (order.status == OrderStatus.pending) {
           final updatedOrder = order.copyWith(status: OrderStatus.cancelled);
           final index = _mockOrders.indexOf(order);
           _mockOrders[index] = updatedOrder;
           return Right(updatedOrder);
        } else {
           return Left(UnknownFailure('Order cannot be cancelled at this stage'));
        }
     } catch (e) {
       return Left(UnknownFailure('Order not found'));
     }
  }

  @override
  Future<Either<Failure, Order>> updateTip(String id, double tip) async {
     await Future.delayed(const Duration(milliseconds: 100));
     try {
       final order = _mockOrders.firstWhere((order) => order.id == id);
        final updatedOrder = order.copyWith(tip: tip, total: order.total - order.tip + tip);
        final index = _mockOrders.indexOf(order);
        _mockOrders[index] = updatedOrder;
        return Right(updatedOrder);
     } catch (e) {
        return Left(UnknownFailure('Order not found'));
     }
  }

  @override
  Future<Either<Failure, List<Order>>> getShopOrders({
    required String shopId,
    OrderStatus? status,
    int page = 1,
    int limit = 20,
  }) async => Left(const UnknownFailure('Method not implemented'));

  @override
  Future<Either<Failure, Order>> updateOrderStatus({
    required String orderId,
    required OrderStatus status,
    String? rejectionReason,
    DateTime? estimatedDeliveryTime,
  }) async => Left(const UnknownFailure('Method not implemented'));

  @override
  Future<Either<Failure, List<Order>>> getAssignedOrders({
    OrderStatus? status,
    int page = 1,
    int limit = 20,
  }) async => Left(const UnknownFailure('Method not implemented'));

  @override
  Future<Either<Failure, Order>> updateOrderLocation({
    required String orderId,
    required double latitude,
    required double longitude,
  }) async => Left(const UnknownFailure('Method not implemented'));

  @override
  Future<Either<Failure, Order>> markOrderAsDelivered(String orderId) async => Left(const UnknownFailure('Method not implemented'));

  @override
  Future<Either<Failure, List<Order>>> getAllOrders({
    String? userId,
    String? shopId,
    String? deliveryPersonId,
    OrderStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    int page = 1,
    int limit = 20,
  }) async => Left(const UnknownFailure('Method not implemented'));

  @override
  Future<Either<Failure, Order>> assignOrderToDeliveryPerson({
    required String orderId,
    required String deliveryPersonId,
  }) async => Left(const UnknownFailure('Method not implemented'));
} 