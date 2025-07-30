import 'package:dio/dio.dart';

class DeliveryService {
  final Dio _dio;

  DeliveryService(this._dio);

  Future<List<Map<String, dynamic>>> getAvailableOrders() async {
    print('🚀 DeliveryService: Starting getAvailableOrders request');
    
    try {
      print('📡 DeliveryService: Making GET request to /delivery/orders/available');
      final response = await _dio.get('/delivery/orders/available');
      
      print('📥 DeliveryService: Response status: ${response.statusCode}');
      print('📥 DeliveryService: Response data: ${response.data}');
      
      if (response.data['status'] == 'success') {
        final orders = List<Map<String, dynamic>>.from(response.data['data'] ?? []);
        print('✅ DeliveryService: Successfully parsed ${orders.length} available orders');
        
        if (orders.isEmpty) {
          print('⚠️ DeliveryService: No available orders found - this could mean:');
          print('   - No orders with READY_FOR_PICKUP status');
          print('   - All orders already have delivery_person_id assigned');
          print('   - Vendor hasn\'t marked any orders as ready yet');
        } else {
          print('📦 DeliveryService: Available orders:');
          for (int i = 0; i < orders.length; i++) {
            final order = orders[i];
            print('   Order ${i + 1}: ID=${order['id']}, Status=${order['status']}, Shop=${order['shop_name']}, Total=\$${order['total']}');
          }
        }
        
        return orders;
      } else {
        print('❌ DeliveryService: Failed to load orders - response status is not success');
        throw Exception('Failed to load available orders');
      }
    } on DioException catch (e) {
      print('❌ DeliveryService: DioException occurred in getAvailableOrders');
      print('❌ DeliveryService: Status code: ${e.response?.statusCode}');
      print('❌ DeliveryService: Response data: ${e.response?.data}');
      print('❌ DeliveryService: Error message: ${e.message}');
      
      if (e.response?.statusCode == 401) {
        print('🔐 DeliveryService: Authentication error - token may be expired');
        throw Exception('Authentication required. Please login again.');
      } else if (e.response?.statusCode == 403) {
        print('🚫 DeliveryService: Permission denied - delivery role required');
        throw Exception('Access denied. Delivery role required.');
      } else {
        throw Exception('Failed to load orders: ${e.message}');
      }
    } catch (e) {
      print('❌ DeliveryService: Unexpected error in getAvailableOrders: $e');
      rethrow;
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

  Future<Map<String, dynamic>> getOrderDetails(String orderId) async {
    print('🚀 DeliveryService: Starting getOrderDetails for orderId: $orderId');
    try {
      print('📡 DeliveryService: Making GET request to /orders/$orderId');
      final response = await _dio.get('/orders/$orderId');
      print('📥 DeliveryService: Order details response status: ${response.statusCode}');
      print('📥 DeliveryService: Order details response data: ${response.data}');
      
      if (response.statusCode == 200) {
        print('✅ DeliveryService: Order details loaded successfully');
        return response.data;
      } else {
        print('❌ DeliveryService: Failed to load order details - status: ${response.statusCode}');
        throw Exception('Failed to load order details');
      }
    } on DioException catch (e) {
      print('❌ DeliveryService: DioException in getOrderDetails');
      print('❌ DeliveryService: Status code: ${e.response?.statusCode}');
      print('❌ DeliveryService: Response data: ${e.response?.data}');
      print('❌ DeliveryService: Error message: ${e.message}');
      throw Exception('Failed to load order details: ${e.message}');
    } catch (e) {
      print('❌ DeliveryService: Unexpected error in getOrderDetails: $e');
      rethrow;
    }
  }

  Future<void> acceptOrder(String orderId) async {
    print('🚀 DeliveryService: Starting acceptOrder for orderId: $orderId');
    try {
      print('📡 DeliveryService: Making PATCH request to /delivery/orders/$orderId/accept');
      final response = await _dio.patch('/delivery/orders/$orderId/accept');
      print('📥 DeliveryService: Accept order response status: ${response.statusCode}');
      print('📥 DeliveryService: Accept order response data: ${response.data}');
      
      if (response.data['status'] == 'success') {
        print('✅ DeliveryService: Order accepted successfully');
      } else {
        print('❌ DeliveryService: Failed to accept order - response status is not success');
        throw Exception('Failed to accept order');
      }
    } on DioException catch (e) {
      print('❌ DeliveryService: DioException in acceptOrder');
      print('❌ DeliveryService: Status code: ${e.response?.statusCode}');
      print('❌ DeliveryService: Response data: ${e.response?.data}');
      print('❌ DeliveryService: Error message: ${e.message}');
      throw Exception('Failed to accept order: ${e.message}');
    } catch (e) {
      print('❌ DeliveryService: Unexpected error in acceptOrder: $e');
      rethrow;
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