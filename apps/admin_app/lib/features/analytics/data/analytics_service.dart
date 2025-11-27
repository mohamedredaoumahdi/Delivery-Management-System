import 'package:dio/dio.dart';

class AnalyticsService {
  final Dio _dio;

  AnalyticsService(this._dio);

  Future<List<dynamic>> getUserAnalytics() async {
    try {
      final response = await _dio.get('/admin/analytics/users');
      if (response.data['status'] == 'success') {
        final data = response.data['data'];
        // Handle both List and Map responses
        if (data is List) {
          return data;
        } else if (data is Map) {
          return [data];
        }
        return [];
      }
      throw Exception('Failed to load user analytics');
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('Failed to load user analytics: ${e.toString()}');
    }
  }

  Future<List<dynamic>> getOrderAnalytics() async {
    try {
      final response = await _dio.get('/admin/analytics/orders');
      if (response.data['status'] == 'success') {
        final data = response.data['data'];
        // Handle both List and Map responses
        if (data is List) {
          return data;
        } else if (data is Map) {
          return [data];
        }
        return [];
      }
      throw Exception('Failed to load order analytics');
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('Failed to load order analytics: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> getRevenueAnalytics() async {
    try {
      final response = await _dio.get('/admin/analytics/revenue');
      if (response.data['status'] == 'success') {
        return response.data['data'];
      }
      throw Exception('Failed to load revenue analytics');
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('Failed to load revenue analytics: ${e.toString()}');
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
        case 500:
          return 'Server error. Please try again later.';
        default:
          return 'Something went wrong. Please try again.';
      }
    }
    
    return 'Network error. Please check your connection.';
  }
}

