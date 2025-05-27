import 'package:dio/dio.dart';
import '../config/environment.dart';
import '../models/api_response.dart';
import 'storage_service.dart';

/// A unified API client for making HTTP requests
class ApiClient {
  /// The Dio HTTP client
  final Dio _dio;
  
  /// The storage service for managing tokens
  final StorageService _storage;
  
  /// Creates an API client
  ApiClient({
    required Dio dio,
    required StorageService storage,
  }) : _dio = dio,
       _storage = storage {
    _setupInterceptors();
  }
  
  /// Sets up interceptors for the Dio client
  void _setupInterceptors() {
    _dio.options.baseUrl = Environment.baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
    _dio.options.headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.getString('auth_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          // Handle token refresh or logout
          await _storage.remove('auth_token');
        }
        return handler.next(error);
      },
    ));
    
    if (Environment.isDebug) {
      _dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
      ));
    }
  }
  
  /// Sets the authentication token
  Future<void> setAuthToken(String token) async {
    await _storage.setString('auth_token', token);
  }
  
  /// Clears the authentication token
  Future<void> clearAuthToken() async {
    await _storage.remove('auth_token');
  }
  
  /// Makes a GET request
  Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
      );
      return _handleResponse(response, fromJson);
    } on DioException catch (e) {
      return _handleError(e);
    }
  }
  
  /// Makes a POST request
  Future<ApiResponse<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
      );
      return _handleResponse(response, fromJson);
    } on DioException catch (e) {
      return _handleError(e);
    }
  }
  
  /// Makes a PUT request
  Future<ApiResponse<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final response = await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
      );
      return _handleResponse(response, fromJson);
    } on DioException catch (e) {
      return _handleError(e);
    }
  }
  
  /// Makes a PATCH request
  Future<ApiResponse<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final response = await _dio.patch(
        path,
        data: data,
        queryParameters: queryParameters,
      );
      return _handleResponse(response, fromJson);
    } on DioException catch (e) {
      return _handleError(e);
    }
  }
  
  /// Makes a DELETE request
  Future<ApiResponse<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final response = await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
      );
      return _handleResponse(response, fromJson);
    } on DioException catch (e) {
      return _handleError(e);
    }
  }
  
  /// Handles the API response
  ApiResponse<T> _handleResponse<T>(
    Response response,
    T Function(dynamic)? fromJson,
  ) {
    if (response.statusCode! >= 200 && response.statusCode! < 300) {
      if (fromJson != null) {
        return ApiResponse.success(
          fromJson(response.data['data']),
          message: response.data['message'],
        );
      } else {
        return ApiResponse.success(
          response.data['data'] as T,
          message: response.data['message'],
        );
      }
    } else {
      return ApiResponse.error(
        response.data['message'] ?? 'Unknown error occurred',
        statusCode: response.statusCode,
      );
    }
  }
  
  /// Handles API errors
  ApiResponse<T> _handleError<T>(DioException error) {
    if (error.response != null) {
      final data = error.response?.data;
      final message = data is Map
          ? data['message'] as String?
          : 'Server error occurred';
      
      return ApiResponse.error(
        message ?? error.message ?? 'Unknown error occurred',
        statusCode: error.response?.statusCode,
      );
    } else if (error.type == DioExceptionType.connectionTimeout ||
               error.type == DioExceptionType.sendTimeout ||
               error.type == DioExceptionType.receiveTimeout) {
      return ApiResponse.error(
        'Request timed out',
        statusCode: 408,
      );
    } else if (error.type == DioExceptionType.connectionError) {
      return ApiResponse.error(
        'No internet connection',
        statusCode: 0,
      );
    } else {
      return ApiResponse.error(
        error.message ?? 'Unknown error occurred',
        statusCode: 500,
      );
    }
  }
} 