import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  final Dio _dio;
  final SharedPreferences _prefs;
  static const String _baseUrl = 'http://localhost:3000/api'; // Update with your backend URL

  ApiClient(this._prefs) : _dio = Dio(BaseOptions(
    baseUrl: _baseUrl,
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 3),
  )) {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = _prefs.getString('auth_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (DioException error, handler) {
        // Handle 401 Unauthorized - clear invalid token
        if (error.response?.statusCode == 401) {
          _prefs.remove('auth_token');
        }
        return handler.next(error);
      },
    ));
  }

  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) async {
    try {
      return await _dio.get(path, queryParameters: queryParameters);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Sends a POST request to the specified path with optional data
  Future<Response> post(String path, {dynamic data}) async {
    try {
      return await _dio.post(path, data: data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> put(String path, {dynamic data}) async {
    try {
      return await _dio.put(path, data: data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> delete(String path) async {
    try {
      return await _dio.delete(path);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> setAuthToken(String token) async {
    await _prefs.setString('auth_token', token);
  }

  /// Handles DioException and converts it to a user-friendly ApiException
  /// Extracts error messages from response data when available
  Exception _handleError(DioException error) {
    if (error.response != null) {
      final responseData = error.response?.data;
      String errorMessage = 'An error occurred';
      
      if (responseData is Map<String, dynamic>) {
        errorMessage = responseData['message'] ?? 
                      responseData['error'] ?? 
                      'Invalid response from server: ${responseData.toString()}';
      } else if (responseData is String) {
        errorMessage = responseData;
      }
      
      return ApiException(
        error.response?.statusCode ?? 500,
        errorMessage,
      );
    }
    return ApiException(500, 'Network error occurred');
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException(this.statusCode, this.message);

  @override
  String toString() => 'ApiException: [$statusCode] $message';
} 