import 'package:dio/dio.dart';

class DeliveryService {
  final Dio _dio;

  DeliveryService(this._dio);

  Future<List<Map<String, dynamic>>> getAvailableOrders() async {
    try {
      final response = await _dio.get('/delivery/orders/available');
      
      if (response.data['status'] == 'success') {
        return List<Map<String, dynamic>>.from(response.data['data'] ?? []);
      } else {
        throw Exception('Failed to load available orders');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Authentication required. Please login again.');
      } else if (e.response?.statusCode == 403) {
        throw Exception('Access denied. Delivery role required.');
      } else {
        throw Exception('Failed to load orders: ${e.message}');
      }
    }
  }

  Future<Map<String, dynamic>> getAssignedOrders() async {
    try {
      final response = await _dio.get('/delivery/orders');
      
      if (response.data['status'] == 'success') {
        return {
          'orders': List<Map<String, dynamic>>.from(response.data['data'] ?? [])
        };
      } else {
        throw Exception('Failed to load assigned orders');
      }
    } on DioException catch (e) {
      throw Exception('Failed to load assigned orders: ${e.message}');
    }
  }

  Future<void> acceptOrder(String orderId) async {
    try {
      final response = await _dio.patch('/delivery/orders/$orderId/accept');
      
      if (response.data['status'] != 'success') {
        throw Exception('Failed to accept order');
      }
    } on DioException catch (e) {
      throw Exception('Failed to accept order: ${e.message}');
    }
  }

  Future<void> markPickedUp(String orderId) async {
    try {
      final response = await _dio.patch('/delivery/orders/$orderId/pickup');
      
      if (response.data['status'] != 'success') {
        throw Exception('Failed to mark order as picked up');
      }
    } on DioException catch (e) {
      throw Exception('Failed to mark pickup: ${e.message}');
    }
  }

  Future<void> markDelivered(String orderId) async {
    try {
      final response = await _dio.patch('/delivery/orders/$orderId/delivered');
      
      if (response.data['status'] != 'success') {
        throw Exception('Failed to mark order as delivered');
      }
    } on DioException catch (e) {
      throw Exception('Failed to mark delivered: ${e.message}');
    }
  }

  Future<Map<String, dynamic>> getStats() async {
    try {
      final response = await _dio.get('/delivery/stats');
      
      if (response.data['status'] == 'success') {
        return response.data['data'];
      } else {
        throw Exception('Failed to load stats');
      }
    } on DioException catch (e) {
      throw Exception('Failed to load stats: ${e.message}');
    }
  }

  Future<Map<String, dynamic>> getEarnings() async {
    try {
      final response = await _dio.get('/delivery/earnings');
      
      if (response.data['status'] == 'success') {
        return response.data['data'];
      } else {
        throw Exception('Failed to load earnings');
      }
    } on DioException catch (e) {
      throw Exception('Failed to load earnings: ${e.message}');
    }
  }
} 