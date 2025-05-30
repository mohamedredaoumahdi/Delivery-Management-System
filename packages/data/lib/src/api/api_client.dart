
import 'package:core/core.dart';
import 'package:dio/dio.dart';

/// A client for making HTTP requests to the API
class ApiClient {
  /// The underlying Dio client
  final Dio _dio;

  /// Creates an API client
  ApiClient(this._dio);

  /// Makes a GET request to the specified endpoint
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onReceiveProgress: onReceiveProgress,
      );
      return _handleResponse(response);
    } on DioException catch (e) {
      throw ErrorHandler.handleDioError(e);
    }
  }

  /// Makes a POST request to the specified endpoint
  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
      return _handleResponse(response);
    } on DioException catch (e) {
      throw ErrorHandler.handleDioError(e);
    }
  }

  /// Makes a PUT request to the specified endpoint
  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      final response = await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
      return _handleResponse(response);
    } on DioException catch (e) {
      throw ErrorHandler.handleDioError(e);
    }
  }

  /// Makes a PATCH request to the specified endpoint
  Future<Response> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      final response = await _dio.patch(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
      return _handleResponse(response);
    } on DioException catch (e) {
      throw ErrorHandler.handleDioError(e);
    }
  }

  /// Makes a DELETE request to the specified endpoint
  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return _handleResponse(response);
    } on DioException catch (e) {
      throw ErrorHandler.handleDioError(e);
    }
  }

  /// Uploads a file to the specified endpoint
  Future<Response> uploadFile(
    String path, {
    required String filePath,
    String? fileName,
    Map<String, dynamic>? formData,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      final multipartData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          filePath,
          filename: fileName,
        ),
        ...?formData,
      });

      final response = await _dio.post(
        path,
        data: multipartData,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
      return _handleResponse(response);
    } on DioException catch (e) {
      throw ErrorHandler.handleDioError(e);
    }
  }

  /// Handles the response and throws an appropriate exception if there's an error
  Response _handleResponse(Response response) {
    if (response.statusCode! >= 200 && response.statusCode! < 300) {
      return response;
    }

    throw ErrorHandler.handleDioError(
      DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
      ),
    );
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