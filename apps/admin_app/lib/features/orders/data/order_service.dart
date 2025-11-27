import 'package:dio/dio.dart';
import 'models/order_model.dart';

class OrderService {
  final Dio _dio;

  OrderService(this._dio);

  Future<List<OrderModel>> getOrders() async {
    try {
      final response = await _dio.get('/admin/orders');
      
      if (response.data['status'] == 'success') {
        final List<dynamic> ordersData = response.data['data'];
        return ordersData.map((json) => OrderModel.fromJson(json)).toList();
      }
      
      throw Exception('Failed to load orders');
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('Failed to load orders: ${e.toString()}');
    }
  }

  Future<OrderModel> getOrderById(String id) async {
    try {
      final response = await _dio.get('/admin/orders/$id');
      
      if (response.data['status'] == 'success') {
        return OrderModel.fromJson(response.data['data']);
      }
      
      throw Exception('Failed to load order');
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('Failed to load order: ${e.toString()}');
    }
  }

  Future<OrderModel> updateOrderStatus(String id, String status) async {
    try {
      final response = await _dio.put('/admin/orders/$id/status', data: {'status': status});
      
      if (response.data['status'] == 'success') {
        return OrderModel.fromJson(response.data['data']);
      }
      
      throw Exception('Failed to update order');
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('Failed to update order: ${e.toString()}');
    }
  }

  Future<OrderModel> assignDeliveryAgent(String orderId, String deliveryPersonId) async {
    try {
      final response = await _dio.post(
        '/admin/orders/$orderId/assign-delivery',
        data: {'deliveryPersonId': deliveryPersonId},
      );
      
      if (response.data['status'] == 'success') {
        return OrderModel.fromJson(response.data['data']);
      }
      
      throw Exception('Failed to assign delivery agent');
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('Failed to assign delivery agent: ${e.toString()}');
    }
  }

  Future<OrderModel> cancelOrder(String orderId, String reason) async {
    try {
      final response = await _dio.post(
        '/admin/orders/$orderId/cancel',
        data: {'reason': reason},
      );
      
      if (response.data['status'] == 'success') {
        return OrderModel.fromJson(response.data['data']);
      }
      
      throw Exception('Failed to cancel order');
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('Failed to cancel order: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> refundOrder(String orderId, String reason, {double? amount}) async {
    try {
      final response = await _dio.post(
        '/admin/orders/$orderId/refund',
        data: {
          'reason': reason,
          if (amount != null) 'amount': amount,
        },
      );
      
      if (response.data['status'] == 'success') {
        return {
          'order': OrderModel.fromJson(response.data['data']),
          'refundAmount': response.data['refundAmount'],
        };
      }
      
      throw Exception('Failed to refund order');
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('Failed to refund order: ${e.toString()}');
    }
  }

  Future<OrderModel> updateOrderFees(
    String orderId, {
    double? deliveryFee,
    double? discount,
    String? reason,
  }) async {
    try {
      final response = await _dio.put(
        '/admin/orders/$orderId/fees',
        data: {
          if (deliveryFee != null) 'deliveryFee': deliveryFee,
          if (discount != null) 'discount': discount,
          if (reason != null) 'reason': reason,
        },
      );
      
      if (response.data['status'] == 'success') {
        return OrderModel.fromJson(response.data['data']);
      }
      
      throw Exception('Failed to update order fees');
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('Failed to update order fees: ${e.toString()}');
    }
  }

  Future<List<Map<String, dynamic>>> getAvailableDeliveryAgents() async {
    try {
      final response = await _dio.get('/admin/delivery-agents');
      
      if (response.data['status'] == 'success') {
        return List<Map<String, dynamic>>.from(response.data['data']);
      }
      
      throw Exception('Failed to load delivery agents');
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('Failed to load delivery agents: ${e.toString()}');
    }
  }

  String _handleDioError(DioException e) {
    if (e.response != null) {
      final statusCode = e.response!.statusCode;
      final data = e.response!.data;
      
      switch (statusCode) {
        case 400:
          return data['message'] ?? 'Invalid request';
        case 401:
          return 'Unauthorized. Please login again.';
        case 403:
          return 'Access denied';
        case 404:
          return 'Order not found';
        case 500:
          return 'Server error. Please try again later.';
        default:
          return 'Something went wrong. Please try again.';
      }
    }
    
    return 'Network error. Please check your connection.';
  }
}

