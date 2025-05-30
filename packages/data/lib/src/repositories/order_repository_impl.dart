import 'package:dartz/dartz.dart' as dartz;
import 'package:domain/domain.dart';
import 'package:core/core.dart' show 
  LoggerService, 
  NetworkException, 
  ServerFailure,
  NetworkFailure,
  TimeoutFailure,
  UnknownFailure,
  AuthFailure,
  ValidationFailure;
import 'package:core/src/exceptions/api_exceptions.dart' show ApiException, TimeoutException;

import '../api/api_client.dart' as data_api;
import '../models/order_model.dart';

/// Implementation of the [OrderRepository]
class OrderRepositoryImpl implements OrderRepository {
  /// API client for network requests
  final data_api.ApiClient apiClient;
  
  /// Logger service
  final LoggerService logger;

  /// Creates an order repository
  OrderRepositoryImpl({
    required this.apiClient,
    required this.logger,
  });

  @override
  Future<dartz.Either<Failure, Order>> placeOrder({
    required String shopId,
    required List<OrderItem> items,
    required String deliveryAddress,
    required double deliveryLatitude,
    required double deliveryLongitude,
    String? deliveryInstructions,
    required PaymentMethod paymentMethod,
    double tip = 0,
  }) async {
    try {
      final response = await apiClient.post(
        '/orders',
        data: {
          'shopId': shopId,
          'items': items.map((item) {
            final itemData = <String, dynamic>{
            'productId': item.productId,
            'productName': item.productName,
            'productPrice': item.productPrice,
            'quantity': item.quantity,
            'totalPrice': item.totalPrice,
            };
            
            // Only include instructions if they exist and are not empty
            if (item.instructions != null && item.instructions!.trim().isNotEmpty) {
              itemData['instructions'] = item.instructions!.trim();
            }
            
            return itemData;
          }).toList(),
          'deliveryAddress': deliveryAddress,
          'deliveryLatitude': deliveryLatitude,
          'deliveryLongitude': deliveryLongitude,
          'deliveryInstructions': deliveryInstructions,
          'paymentMethod': _mapPaymentMethodToBackend(paymentMethod),
          'tip': tip,
        },
      );

      // Handle different response formats from the backend
      final responseData = response.data;
      Map<String, dynamic> orderData;
      
      if (responseData is Map<String, dynamic>) {
        // Check if the response has a 'data' wrapper
        if (responseData.containsKey('data') && responseData['data'] != null) {
          orderData = responseData['data'] as Map<String, dynamic>;
        } else {
          // Order data is returned directly
          orderData = responseData;
        }
      } else {
        throw Exception('Invalid response format');
      }

      final orderModel = OrderModel.fromJson(orderData);
      return dartz.Right(orderModel.toDomain());
    } catch (e) {
      logger.e('Error placing order', e);
      return dartz.Left(_handleError(e));
    }
  }

  /// Map PaymentMethod enum to backend expected format
  String _mapPaymentMethodToBackend(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cashOnDelivery:
        return 'CASH_ON_DELIVERY';
      case PaymentMethod.card:
        return 'CARD';
      case PaymentMethod.wallet:
        return 'WALLET';
      case PaymentMethod.bankTransfer:
        return 'BANK_TRANSFER';
    }
  }

  @override
  Future<dartz.Either<Failure, List<Order>>> getUserOrders({
    OrderStatus? status,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      print('🚀 OrderRepositoryImpl: getUserOrders called with status: $status, page: $page, limit: $limit');
      
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };
      
      if (status != null) {
        queryParams['status'] = status.toString().split('.').last;
      }

      print('📞 OrderRepositoryImpl: Making API call to /orders with params: $queryParams');
      
      final response = await apiClient.get(
        '/orders',
        queryParameters: queryParams,
      );

      print('✅ OrderRepositoryImpl: API call successful, response status: ${response.statusCode}');
      print('📋 OrderRepositoryImpl: Response data type: ${response.data.runtimeType}');
      print('📋 OrderRepositoryImpl: Response data: ${response.data}');

      // Handle the response data
      final responseData = response.data;
      List<dynamic> ordersData;
      
      if (responseData is Map<String, dynamic> && responseData.containsKey('data')) {
        ordersData = responseData['data'] as List<dynamic>;
        print('📦 OrderRepositoryImpl: Found data wrapper, orders count: ${ordersData.length}');
      } else if (responseData is List<dynamic>) {
        ordersData = responseData;
        print('📦 OrderRepositoryImpl: Direct list response, orders count: ${ordersData.length}');
      } else {
        ordersData = [];
        print('⚠️ OrderRepositoryImpl: Unexpected response format, using empty list');
      }

      final orders = ordersData
          .map((orderJson) => OrderModel.fromJson(orderJson as Map<String, dynamic>).toDomain())
          .toList();

      print('🎯 OrderRepositoryImpl: Successfully parsed ${orders.length} orders');
      return dartz.Right(orders);
    } catch (e) {
      print('❌ OrderRepositoryImpl: Error getting user orders: $e');
      logger.e('Error getting user orders', e);
      return dartz.Left(_handleError(e));
    }
  }

  @override
  Future<dartz.Either<Failure, Order>> getOrderById(String id) async {
    try {
      final response = await apiClient.get('/orders/$id');
      
      // Handle different response formats from the backend
      final responseData = response.data;
      Map<String, dynamic> orderData;
      
      if (responseData is Map<String, dynamic>) {
        // Check if the response has a 'data' wrapper
        if (responseData.containsKey('data') && responseData['data'] != null) {
          orderData = responseData['data'] as Map<String, dynamic>;
        } else {
          // Order data is returned directly
          orderData = responseData;
        }
      } else {
        throw Exception('Invalid response format');
      }

      final orderModel = OrderModel.fromJson(orderData);
      return dartz.Right(orderModel.toDomain());
    } catch (e) {
      logger.e('Error getting order by ID', e);
      return dartz.Left(_handleError(e));
    }
  }

  @override
  Future<dartz.Either<Failure, Order>> cancelOrder(String id, {String? reason}) async {
    try {
      final response = await apiClient.patch(
        '/orders/$id/cancel',
        data: {
          'reason': reason,
        },
      );

      // Handle different response formats from the backend
      final responseData = response.data;
      Map<String, dynamic> orderData;
      
      if (responseData is Map<String, dynamic>) {
        // Check if the response has a 'data' wrapper
        if (responseData.containsKey('data') && responseData['data'] != null) {
          orderData = responseData['data'] as Map<String, dynamic>;
        } else {
          // Order data is returned directly
          orderData = responseData;
        }
      } else {
        throw Exception('Invalid response format');
      }

      final orderModel = OrderModel.fromJson(orderData);
      return dartz.Right(orderModel.toDomain());
    } catch (e) {
      logger.e('Error cancelling order', e);
      return dartz.Left(_handleError(e));
    }
  }

  @override
  Future<dartz.Either<Failure, Order>> updateTip(String id, double tip) async {
    try {
      final response = await apiClient.patch(
        '/orders/$id/tip',
        data: {
          'tip': tip,
        },
      );

      // Handle different response formats from the backend
      final responseData = response.data;
      Map<String, dynamic> orderData;
      
      if (responseData is Map<String, dynamic>) {
        // Check if the response has a 'data' wrapper
        if (responseData.containsKey('data') && responseData['data'] != null) {
          orderData = responseData['data'] as Map<String, dynamic>;
        } else {
          // Order data is returned directly
          orderData = responseData;
        }
      } else {
        throw Exception('Invalid response format');
      }

      final orderModel = OrderModel.fromJson(orderData);
      return dartz.Right(orderModel.toDomain());
    } catch (e) {
      logger.e('Error updating tip', e);
      return dartz.Left(_handleError(e));
    }
  }

  @override
  Future<dartz.Either<Failure, List<Order>>> getShopOrders({
    required String shopId,
    OrderStatus? status,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
        'shopId': shopId,
      };
      
      if (status != null) {
        queryParams['status'] = status.toString().split('.').last;
      }

      final response = await apiClient.get(
        '/vendor/orders',
        queryParameters: queryParams,
      );

      final ordersData = response.data['data'] as List<dynamic>;
      final orders = ordersData
          .map((orderJson) => OrderModel.fromJson(orderJson).toDomain())
          .toList();

      return dartz.Right(orders);
    } catch (e) {
      logger.e('Error getting shop orders', e);
      return dartz.Left(_handleError(e));
    }
  }

  @override
  Future<dartz.Either<Failure, Order>> updateOrderStatus({
    required String orderId,
    required OrderStatus status,
    String? rejectionReason,
    DateTime? estimatedDeliveryTime,
  }) async {
    try {
      final data = <String, dynamic>{
        'status': status.toString().split('.').last,
      };
      
      if (rejectionReason != null) {
        data['rejectionReason'] = rejectionReason;
      }
      
      if (estimatedDeliveryTime != null) {
        data['estimatedDeliveryTime'] = estimatedDeliveryTime.toIso8601String();
      }

      final response = await apiClient.patch(
        '/vendor/orders/$orderId/status',
        data: data,
      );

      // Handle different response formats from the backend
      final responseData = response.data;
      Map<String, dynamic> orderData;
      
      if (responseData is Map<String, dynamic>) {
        // Check if the response has a 'data' wrapper
        if (responseData.containsKey('data') && responseData['data'] != null) {
          orderData = responseData['data'] as Map<String, dynamic>;
        } else {
          // Order data is returned directly
          orderData = responseData;
        }
      } else {
        throw Exception('Invalid response format');
      }

      final orderModel = OrderModel.fromJson(orderData);
      return dartz.Right(orderModel.toDomain());
    } catch (e) {
      logger.e('Error updating order status', e);
      return dartz.Left(_handleError(e));
    }
  }

  @override
  Future<dartz.Either<Failure, List<Order>>> getAssignedOrders({
    OrderStatus? status,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };
      
      if (status != null) {
        queryParams['status'] = status.toString().split('.').last;
      }

      final response = await apiClient.get(
        '/delivery/orders',
        queryParameters: queryParams,
      );

      final ordersData = response.data['data'] as List<dynamic>;
      final orders = ordersData
          .map((orderJson) => OrderModel.fromJson(orderJson).toDomain())
          .toList();

      return dartz.Right(orders);
    } catch (e) {
      logger.e('Error getting assigned orders', e);
      return dartz.Left(_handleError(e));
    }
  }

  @override
  Future<dartz.Either<Failure, Order>> updateOrderLocation({
    required String orderId,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final response = await apiClient.patch(
        '/delivery/orders/$orderId/location',
        data: {
          'latitude': latitude,
          'longitude': longitude,
        },
      );

      // Handle different response formats from the backend
      final responseData = response.data;
      Map<String, dynamic> orderData;
      
      if (responseData is Map<String, dynamic>) {
        // Check if the response has a 'data' wrapper
        if (responseData.containsKey('data') && responseData['data'] != null) {
          orderData = responseData['data'] as Map<String, dynamic>;
        } else {
          // Order data is returned directly
          orderData = responseData;
        }
      } else {
        throw Exception('Invalid response format');
      }

      final orderModel = OrderModel.fromJson(orderData);
      return dartz.Right(orderModel.toDomain());
    } catch (e) {
      logger.e('Error updating order location', e);
      return dartz.Left(_handleError(e));
    }
  }

  @override
  Future<dartz.Either<Failure, Order>> markOrderAsDelivered(String orderId) async {
    try {
      final response = await apiClient.patch(
        '/delivery/orders/$orderId/delivered',
        data: {
          'deliveredAt': DateTime.now().toIso8601String(),
        },
      );

      // Handle different response formats from the backend
      final responseData = response.data;
      Map<String, dynamic> orderData;
      
      if (responseData is Map<String, dynamic>) {
        // Check if the response has a 'data' wrapper
        if (responseData.containsKey('data') && responseData['data'] != null) {
          orderData = responseData['data'] as Map<String, dynamic>;
        } else {
          // Order data is returned directly
          orderData = responseData;
        }
      } else {
        throw Exception('Invalid response format');
      }

      final orderModel = OrderModel.fromJson(orderData);
      return dartz.Right(orderModel.toDomain());
    } catch (e) {
      logger.e('Error marking order as delivered', e);
      return dartz.Left(_handleError(e));
    }
  }

  @override
  Future<dartz.Either<Failure, List<Order>>> getAllOrders({
    String? userId,
    String? shopId,
    String? deliveryPersonId,
    OrderStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };
      
      if (userId != null) {
        queryParams['userId'] = userId;
      }
      
      if (shopId != null) {
        queryParams['shopId'] = shopId;
      }
      
      if (deliveryPersonId != null) {
        queryParams['deliveryPersonId'] = deliveryPersonId;
      }
      
      if (status != null) {
        queryParams['status'] = status.toString().split('.').last;
      }
      
      if (startDate != null) {
        queryParams['startDate'] = startDate.toIso8601String();
      }
      
      if (endDate != null) {
        queryParams['endDate'] = endDate.toIso8601String();
      }

      final response = await apiClient.get(
        '/admin/orders',
        queryParameters: queryParams,
      );

      final ordersData = response.data['data'] as List<dynamic>;
      final orders = ordersData
          .map((orderJson) => OrderModel.fromJson(orderJson).toDomain())
          .toList();

      return dartz.Right(orders);
    } catch (e) {
      logger.e('Error getting all orders', e);
      return dartz.Left(_handleError(e));
    }
  }

  @override
  Future<dartz.Either<Failure, Order>> assignOrderToDeliveryPerson({
    required String orderId,
    required String deliveryPersonId,
  }) async {
    try {
      final response = await apiClient.patch(
        '/admin/orders/$orderId/assign',
        data: {
          'deliveryPersonId': deliveryPersonId,
        },
      );

      // Handle different response formats from the backend
      final responseData = response.data;
      Map<String, dynamic> orderData;
      
      if (responseData is Map<String, dynamic>) {
        // Check if the response has a 'data' wrapper
        if (responseData.containsKey('data') && responseData['data'] != null) {
          orderData = responseData['data'] as Map<String, dynamic>;
        } else {
          // Order data is returned directly
          orderData = responseData;
        }
      } else {
        throw Exception('Invalid response format');
      }

      final orderModel = OrderModel.fromJson(orderData);
      return dartz.Right(orderModel.toDomain());
    } catch (e) {
      logger.e('Error assigning order to delivery person', e);
      return dartz.Left(_handleError(e));
    }
  }

  /// Handle error and convert to Failure
  Failure _handleError(dynamic error) {
    if (error is ApiException && error.statusCode == 401) {
      return const AuthFailure('Authentication failed. Please sign in again.');
    } else if (error is NetworkException) {
      return const NetworkFailure('No internet connection. Please try again.');
    } else if (error is TimeoutException) {
      return const TimeoutFailure('Request timed out. Please try again.');
    } else if (error is ApiException && error.statusCode == 400) {
      return ValidationFailure('order', error.message ?? 'Invalid request');
    } else if (error is ApiException && error.statusCode != null && error.statusCode! >= 500) {
      return ServerFailure(
        error.message ?? 'Server error occurred',
        statusCode: error.statusCode,
      );
    } else {
      return UnknownFailure(error.toString());
    }
  }
}