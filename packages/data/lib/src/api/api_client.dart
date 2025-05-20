import 'dart:convert';
import 'dart:io';

import 'package:core/core.dart';
import 'package:dio/dio.dart';

/// API client for making HTTP requests
class ApiClient {
  /// The base URL of the API
  final String baseUrl;
  
  /// Dio HTTP client
  late final Dio _dio;
  
  /// Creates an API client
  ApiClient({
    required this.baseUrl, 
    Dio? dio,
    Map<String, String>? defaultHeaders,
  }) {
    _dio = dio ?? Dio();
    
    // Set default baseUrl
    _dio.options.baseUrl = baseUrl;
    
    // Set default headers
    _dio.options.headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      ...?defaultHeaders,
    };
    
    // Set default timeout
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 10);
    
    // Add logging interceptor
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      logPrint: (obj) => logger.d(obj.toString()),
    ));
  }
  
  /// Add authorization token to headers
  void setAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }
  
  /// Remove authorization token from headers
  void clearAuthToken() {
    _dio.options.headers.remove('Authorization');
  }
  
  /// Make a GET request
  Future<Map<String, dynamic>> get(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) async {
    try {
      final response = await _dio.get(
        endpoint,
        queryParameters: queryParameters,
        options: Options(headers: headers),
      );
      
      return _handleResponse(response);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  /// Make a POST request
  Future<Map<String, dynamic>> post(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) async {
    try {
      final response = await _dio.post(
        endpoint,
        data: data,
        queryParameters: queryParameters,
        options: Options(headers: headers),
      );
      
      return _handleResponse(response);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  /// Make a PUT request
  Future<Map<String, dynamic>> put(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) async {
    try {
      final response = await _dio.put(
        endpoint,
        data: data,
        queryParameters: queryParameters,
        options: Options(headers: headers),
      );
      
      return _handleResponse(response);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  /// Make a PATCH request
  Future<Map<String, dynamic>> patch(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) async {
    try {
      final response = await _dio.patch(
        endpoint,
        data: data,
        queryParameters: queryParameters,
        options: Options(headers: headers),
      );
      
      return _handleResponse(response);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  /// Make a DELETE request
  Future<Map<String, dynamic>> delete(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) async {
    try {
      final response = await _dio.delete(
        endpoint,
        data: data,
        queryParameters: queryParameters,
        options: Options(headers: headers),
      );
      
      return _handleResponse(response);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  /// Upload a file
  Future<Map<String, dynamic>> uploadFile(
    String endpoint, {
    required File file,
    String fileField = 'file',
    Map<String, dynamic>? data,
    Map<String, String>? headers,
  }) async {
    try {
      final formData = FormData.fromMap({
        fileField: await MultipartFile.fromFile(file.path),
        ...?data,
      });
      
      final response = await _dio.post(
        endpoint,
        data: formData,
        options: Options(headers: {
          ...?headers,
          'Content-Type': 'multipart/form-data',
        }),
      );
      
      return _handleResponse(response);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  /// Handle response based on status code
  Map<String, dynamic> _handleResponse(Response response) {
    final statusCode = response.statusCode;
    
    if (statusCode! >= 200 && statusCode < 300) {
      if (response.data is Map<String, dynamic>) {
        return response.data;
      } else if (response.data is String) {
        try {
          return json.decode(response.data);
        } catch (e) {
          return {'data': response.data};
        }
      } else {
        return {'data': response.data};
      }
    } else {
      throw Exception(
        'API Error: ${response.statusCode} - ${response.statusMessage}',
      );
    }
  }
  
  /// Handle error and convert to appropriate exception
  Exception _handleError(DioException error) {
    logger.e('API Error: ${error.message}', error);
    
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return TimeoutException('Request timed out');
      case DioExceptionType.connectionError:
        return NetworkException('No internet connection');
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final message = error.response?.data?['message'] ?? error.message;
        
        if (statusCode == 401) {
          return UnauthorizedException(message);
        } else if (statusCode == 403) {
          return ForbiddenException(message);
        } else if (statusCode == 404) {
          return NotFoundException(message);
        } else if (statusCode == 422) {
          return ValidationException(message);
        } else {
          return ServerException(message, statusCode: statusCode);
        }
      case DioExceptionType.cancel:
        return RequestCancelledException('Request was cancelled');
      default:
        return UnknownException(error.message ?? 'Unknown error occurred');
    }
  }
}

/// Custom exceptions
class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);
  @override
  String toString() => message;
}

class NetworkException implements Exception {
  final String message;
  NetworkException(this.message);
  @override
  String toString() => message;
}

class ServerException implements Exception {
  final String message;
  final int? statusCode;
  ServerException(this.message, {this.statusCode});
  @override
  String toString() => message;
}

class UnauthorizedException implements Exception {
  final String message;
  UnauthorizedException(this.message);
  @override
  String toString() => message;
}

class ForbiddenException implements Exception {
  final String message;
  ForbiddenException(this.message);
  @override
  String toString() => message;
}

class NotFoundException implements Exception {
  final String message;
  NotFoundException(this.message);
  @override
  String toString() => message;
}

class ValidationException implements Exception {
  final String message;
  ValidationException(this.message);
  @override
  String toString() => message;
}

class RequestCancelledException implements Exception {
  final String message;
  RequestCancelledException(this.message);
  @override
  String toString() => message;
}

class UnknownException implements Exception {
  final String message;
  UnknownException(this.message);
  @override
  String toString() => message;
}