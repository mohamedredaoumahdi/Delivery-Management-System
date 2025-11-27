import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdminAuthService {
  final SharedPreferences _sharedPreferences;
  final Dio _dio;
  
  AdminAuthService(this._sharedPreferences, this._dio);
  
  /// Authenticates an admin user with email and password
  /// Returns user data and stores authentication tokens
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });
      
      // Store tokens securely in SharedPreferences
      if (response.data['data']['accessToken'] != null) {
        await _sharedPreferences.setString('access_token', response.data['data']['accessToken']);
      }
      if (response.data['data']['refreshToken'] != null) {
        await _sharedPreferences.setString('refresh_token', response.data['data']['refreshToken']);
      }
      
      // Check if user is admin
      final user = response.data['data']['user'];
      if (user['role'] != 'ADMIN') {
        await logout();
        throw Exception('Access denied. Admin privileges required.');
      }
      
      return {
        'success': true,
        'user': user,
      };
    } on DioException catch (e) {
      // Handle network and API errors
      String errorMessage = _handleDioError(e);
      throw Exception(errorMessage);
    } catch (e) {
      // Handle unexpected errors
      if (e.toString().contains('Access denied')) {
        rethrow;
      }
      throw Exception('Connection failed. Please ensure:\n1. Backend is running on http://localhost:3000\n2. Check browser console for CORS errors\n3. Try refreshing the page');
    }
  }
  
  /// Logs out the current user by clearing stored tokens
  /// Optionally calls the backend logout endpoint (non-blocking)
  Future<void> logout() async {
    // Get refresh token before clearing (for optional API call)
    final refreshToken = _sharedPreferences.getString('refresh_token');
    
    // Clear tokens immediately to prevent any further API calls
    await _sharedPreferences.remove('access_token');
    await _sharedPreferences.remove('refresh_token');
    
    // Try to call logout API in the background (non-blocking, fire and forget)
    // This is optional and won't block the logout flow
    if (refreshToken != null) {
      // Fire and forget - don't wait for response
      _dio.post('/auth/logout', data: {'refreshToken': refreshToken}).then((_) {
        // Success - tokens already cleared
      }).catchError((e) {
        // Ignore errors - tokens are already cleared
      });
    }
  }
  
  /// Retrieves the current authenticated admin user
  /// Returns null if no valid token or user is not an admin
  Future<Map<String, dynamic>?> getCurrentUser() async {
    final token = _sharedPreferences.getString('access_token');
    if (token == null) {
      return null;
    }
    
    try {
      final response = await _dio.get('/auth/me');
      final user = response.data['data'];
      
      // Verify admin role - logout if user is not admin
      if (user['role'] != 'ADMIN') {
        await logout();
        return null;
      }
      
      return user;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
        await _sharedPreferences.remove('access_token');
        return null;
      }
      await _sharedPreferences.remove('access_token');
      throw Exception('Unable to load your profile. Please login again.');
    } catch (e) {
      await _sharedPreferences.remove('access_token');
      throw Exception('Network error. Please check your connection and try again.');
    }
  }

  /// Handles DioException errors and returns user-friendly error messages
  /// Maps HTTP status codes and network errors to appropriate messages
  String _handleDioError(DioException e) {
    // Handle timeout errors
    if (e.type == DioExceptionType.connectionTimeout || 
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return 'Connection timeout. Please check your internet connection and try again.';
    }
    
    // Handle connection errors
    if (e.type == DioExceptionType.connectionError) {
      return 'Unable to connect to the server. Please check your internet connection.';
    }
    
    // Handle HTTP response errors
    if (e.response != null) {
      final statusCode = e.response!.statusCode;
      final data = e.response!.data;
      
      switch (statusCode) {
        case 400:
          if (data != null && data['message'] != null) {
            return data['message'];
          }
          return 'Invalid request. Please check your input and try again.';
        case 401:
          return 'Invalid email or password. Please check your credentials.';
        case 403:
          return 'Access denied. Admin privileges required.';
        case 404:
          return 'Account not found. Please check your email.';
        case 500:
          return 'Server error. Please try again later.';
        default:
          return 'Something went wrong. Please try again later.';
      }
    }
    
    return 'Network error. Please check your connection and try again.';
  }
}

