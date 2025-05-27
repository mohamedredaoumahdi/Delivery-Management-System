/// A standardized API response model
class ApiResponse<T> {
  /// Whether the request was successful
  final bool success;
  
  /// The response data
  final T? data;
  
  /// Optional message from the server
  final String? message;
  
  /// HTTP status code
  final int? statusCode;
  
  /// Creates an API response
  const ApiResponse({
    required this.success,
    this.data,
    this.message,
    this.statusCode,
  });
  
  /// Creates an API response from JSON
  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic) fromJson,
  ) {
    return ApiResponse<T>(
      success: json['success'] ?? false,
      data: json['data'] != null ? fromJson(json['data']) : null,
      message: json['message'],
      statusCode: json['statusCode'],
    );
  }
  
  /// Creates a successful API response
  factory ApiResponse.success(T data, {String? message}) {
    return ApiResponse<T>(
      success: true,
      data: data,
      message: message,
    );
  }
  
  /// Creates an error API response
  factory ApiResponse.error(String message, {int? statusCode}) {
    return ApiResponse<T>(
      success: false,
      message: message,
      statusCode: statusCode,
    );
  }
  
  /// Converts the response to JSON
  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'data': data,
      'message': message,
      'statusCode': statusCode,
    };
  }
} 