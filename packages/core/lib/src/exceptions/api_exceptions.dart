/// Base class for API-related exceptions
class ApiException implements Exception {
  /// The error message
  final String? message;
  
  /// The HTTP status code
  final int? statusCode;
  
  /// Creates an API exception
  const ApiException({
    this.message,
    this.statusCode,
  });
  
  @override
  String toString() => 'ApiException: $message (Status: $statusCode)';
}

/// Exception thrown when there is a network connectivity issue
class NetworkException implements Exception {
  /// The error message
  final String? message;
  
  /// Creates a network exception
  const NetworkException([this.message]);
  
  @override
  String toString() => 'NetworkException: ${message ?? 'No internet connection'}';
}

/// Exception thrown when a request times out
class TimeoutException implements Exception {
  /// The error message
  final String? message;
  
  /// Creates a timeout exception
  const TimeoutException([this.message]);
  
  @override
  String toString() => 'TimeoutException: ${message ?? 'Request timed out'}';
} 