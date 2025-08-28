import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:core/core.dart';

class DashboardService {
  final Dio _dio;
  final SharedPreferences _prefs;
  final LoggerService _logger;
  static const String _statusKey = 'driver_status';

  DashboardService(this._dio, this._prefs, this._logger);

  Future<void> goOnline() async {
    _logger.i('🚀 DashboardService: Going online');
    try {
      // For now, just update local status since the backend endpoint might not exist
      await _prefs.setString(_statusKey, 'online');
      _logger.i('✅ DashboardService: Successfully went online (local storage)');
      
      // Try to call the backend endpoint, but don't fail if it doesn't exist
      try {
        final response = await _dio.post('/delivery/status/online');
        _logger.i('✅ DashboardService: Backend status updated successfully');
      } catch (e) {
        _logger.w('⚠️ DashboardService: Backend status endpoint not available, using local storage only: $e');
      }
    } catch (e) {
      _logger.e('❌ DashboardService: Error going online: $e');
      rethrow;
    }
  }

  Future<void> goOffline() async {
    _logger.i('🚀 DashboardService: Going offline');
    try {
      // For now, just update local status since the backend endpoint might not exist
      await _prefs.setString(_statusKey, 'offline');
      _logger.i('✅ DashboardService: Successfully went offline (local storage)');
      
      // Try to call the backend endpoint, but don't fail if it doesn't exist
      try {
        final response = await _dio.post('/delivery/status/offline');
        _logger.i('✅ DashboardService: Backend status updated successfully');
      } catch (e) {
        _logger.w('⚠️ DashboardService: Backend status endpoint not available, using local storage only: $e');
      }
    } catch (e) {
      _logger.e('❌ DashboardService: Error going offline: $e');
      rethrow;
    }
  }

  String getStoredStatus() {
    return _prefs.getString(_statusKey) ?? 'offline';
  }

  Future<Map<String, dynamic>> getStats() async {
    _logger.i('🚀 DashboardService: Getting dashboard stats');
    try {
      _logger.i('📡 DashboardService: Making GET request to /delivery/stats');
      final response = await _dio.get('/delivery/stats');
      
      _logger.i('📥 DashboardService: Response status: ${response.statusCode}');
      _logger.i('📥 DashboardService: Response data: ${response.data}');
      
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
          
          _logger.i('🔍 DashboardService: Processing stat - Status: $status, Count: $count');
          
          if (status == 'DELIVERED') {
            statsMap['deliveryCount'] = count;
          }
        }

        _logger.i('✅ DashboardService: Successfully processed stats: $statsMap');
        return statsMap;
      } else {
        _logger.e('❌ DashboardService: Failed to get stats - response status is not success');
        throw Exception('Failed to get stats');
      }
    } catch (e) {
      _logger.e('❌ DashboardService: Error getting stats: $e');
      rethrow;
    }
  }
} 