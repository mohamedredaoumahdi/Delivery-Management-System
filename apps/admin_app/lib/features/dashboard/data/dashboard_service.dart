import 'package:dio/dio.dart';

import 'models/dashboard_overview_model.dart';

class DashboardService {
  final Dio _dio;

  DashboardService(this._dio);

  Future<DashboardOverview> getStatistics() async {
    try {
      final response = await _dio.get('/admin/dashboard/overview');
      if (response.data['status'] == 'success') {
        final data = Map<String, dynamic>.from(response.data['data'] as Map);
        return DashboardOverview.fromJson(data);
      }

      throw Exception('Failed to load dashboard overview');
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('Failed to load statistics: ${e.toString()}');
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
