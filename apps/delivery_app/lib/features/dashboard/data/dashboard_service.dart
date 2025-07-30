import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DashboardService {
  final Dio _dio;
  final SharedPreferences _prefs;
  static const String _statusKey = 'driver_status';

  DashboardService(this._dio, this._prefs);

  Future<void> goOnline() async {
    print('🚀 DashboardService: Going online');
    try {
      // For now, just update local status since the backend endpoint might not exist
      await _prefs.setString(_statusKey, 'online');
      print('✅ DashboardService: Successfully went online (local storage)');
      
      // Try to call the backend endpoint, but don't fail if it doesn't exist
      try {
        final response = await _dio.post('/delivery/status/online');
        print('✅ DashboardService: Backend status updated successfully');
      } catch (e) {
        print('⚠️ DashboardService: Backend status endpoint not available, using local storage only: $e');
      }
    } catch (e) {
      print('❌ DashboardService: Error going online: $e');
      rethrow;
    }
  }

  Future<void> goOffline() async {
    print('🚀 DashboardService: Going offline');
    try {
      // For now, just update local status since the backend endpoint might not exist
      await _prefs.setString(_statusKey, 'offline');
      print('✅ DashboardService: Successfully went offline (local storage)');
      
      // Try to call the backend endpoint, but don't fail if it doesn't exist
      try {
        final response = await _dio.post('/delivery/status/offline');
        print('✅ DashboardService: Backend status updated successfully');
      } catch (e) {
        print('⚠️ DashboardService: Backend status endpoint not available, using local storage only: $e');
      }
    } catch (e) {
      print('❌ DashboardService: Error going offline: $e');
      rethrow;
    }
  }

  String getStoredStatus() {
    return _prefs.getString(_statusKey) ?? 'offline';
  }

  Future<Map<String, dynamic>> getStats() async {
    print('🚀 DashboardService: Getting dashboard stats');
    try {
      print('📡 DashboardService: Making GET request to /delivery/stats');
      final response = await _dio.get('/delivery/stats');
      
      print('📥 DashboardService: Response status: ${response.statusCode}');
      print('📥 DashboardService: Response data: ${response.data}');
      
      if (response.data['status'] == 'success') {
        // Convert the stats array into a map with counts
        final List<dynamic> statsArray = response.data['data'] ?? [];
        final Map<String, dynamic> statsMap = {
          'deliveryCount': 0,
          'earnings': 0.0,
          'onlineMinutes': 0,
          'rating': 5.0,
        };

        for (final stat in statsArray) {
          final String status = stat['status'] ?? '';
          final int count = stat['_count'] ?? 0; // _count is directly an integer
          
          print('🔍 DashboardService: Processing stat - Status: $status, Count: $count');
          
          if (status == 'DELIVERED') {
            statsMap['deliveryCount'] = count;
          }
        }

        print('✅ DashboardService: Successfully processed stats: $statsMap');
        return statsMap;
      } else {
        print('❌ DashboardService: Failed to get stats - response status is not success');
        throw Exception('Failed to get stats');
      }
    } catch (e) {
      print('❌ DashboardService: Error getting stats: $e');
      rethrow;
    }
  }
} 