import 'package:dio/dio.dart';

/// Base class for application exceptions
abstract class AppException implements Exception {
  /// Error message
  final String message;
  
  /// Error code
  final String? code;
  
  /// Original error that caused this exception
  final dynamic originalError;

  /// Creates an application exception
  const AppException(this.message, [this.code, this.originalError]);

  @override
  String toString() => 'AppException: $message ${code != null ? '($code)' : ''}';
}

/// Exception thrown when there is a network connectivity issue
class NetworkException extends AppException {
  /// Creates a network exception
  const NetworkException(super.message, [super.code, super.originalError]);
}

/// Exception thrown when there is a server error
class ServerException extends AppException {
  /// Creates a server exception
  const ServerException(super.message, [super.code, super.originalError]);
}

/// Exception thrown when there is an authentication error
class AuthException extends AppException {
  /// Creates an authentication exception
  const AuthException(super.message, [super.code, super.originalError]);
}

/// Exception thrown when there is a validation error
class ValidationException extends AppException {
  /// Field-specific validation errors
  final Map<String, List<String>>? fieldErrors;
  
  /// Creates a validation exception
  const ValidationException(
    String message, 
    this.fieldErrors, [
    String? code, 
    dynamic originalError
  ]) : super(message, code, originalError);
}

/// Utility class for handling errors
class ErrorHandler {
  /// Handles Dio errors and converts them to appropriate exceptions
  static AppException handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const NetworkException(
          'Connection timeout. Please check your internet connection.',
          'TIMEOUT',
        );
      
      case DioExceptionType.connectionError:
        return const NetworkException(
          'Unable to connect to server. Please check your internet connection.',
          'CONNECTION_ERROR',
        );
      
      case DioExceptionType.badResponse:
        return _handleHttpError(error);
      
      case DioExceptionType.cancel:
        return const NetworkException('Request cancelled', 'CANCELLED');
      
      default:
        return NetworkException(
          'An unexpected error occurred: ${error.message}',
          'UNKNOWN',
          error,
        );
    }
  }

  /// Handles HTTP errors based on status code
  static AppException _handleHttpError(DioException error) {
    final statusCode = error.response?.statusCode;
    final data = error.response?.data;

    switch (statusCode) {
      case 400:
        return _parseValidationError(data) ?? 
               const ServerException('Bad request', 'BAD_REQUEST');
      
      case 401:
        return const AuthException(
          'Authentication failed. Please login again.',
          'UNAUTHORIZED',
        );
      
      case 403:
        return const AuthException(
          'Access denied. You don\'t have permission to perform this action.',
          'FORBIDDEN',
        );
      
      case 404:
        return const ServerException('Resource not found', 'NOT_FOUND');
      
      case 422:
        return _parseValidationError(data) ?? 
               const ValidationException('Validation failed', null, 'VALIDATION_ERROR');
      
      case 500:
        return const ServerException(
          'Internal server error. Please try again later.',
          'INTERNAL_SERVER_ERROR',
        );
      
      case 503:
        return const ServerException(
          'Service unavailable. Please try again later.',
          'SERVICE_UNAVAILABLE',
        );
      
      default:
        return ServerException(
          'Server error ($statusCode). Please try again later.',
          'HTTP_$statusCode',
        );
    }
  }

  /// Parses validation errors from the response data
  static ValidationException? _parseValidationError(dynamic data) {
    if (data is Map<String, dynamic>) {
      // Laravel-style validation errors
      if (data.containsKey('errors') && data['errors'] is Map) {
        final errors = Map<String, List<String>>.from(
          (data['errors'] as Map).map(
            (key, value) => MapEntry(
              key.toString(), 
              (value as List).map((e) => e.toString()).toList(),
            ),
          ),
        );
        
        return ValidationException(
          data['message'] ?? 'Validation failed',
          errors,
          'VALIDATION_ERROR',
        );
      }
      
      // Simple message format
      if (data.containsKey('message')) {
        return ValidationException(
          data['message'].toString(),
          null,
          'VALIDATION_ERROR',
        );
      }
    }
    
    return null;
  }
} 