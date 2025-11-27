import 'package:dio/dio.dart';

/// Remote data source for vendor operations
abstract class VendorRemoteDataSource {
  Future<Map<String, dynamic>> getVendorById(String vendorId);
  Future<Map<String, dynamic>> getCurrentVendor();
  Future<Map<String, dynamic>> updateVendor(Map<String, dynamic> vendorData);
  Future<Map<String, dynamic>> getDashboardData(String vendorId);
  Future<Map<String, dynamic>> updateVendorStatus(String vendorId, String status);
  Future<String> uploadDocument(String vendorId, String filePath, String documentType);
  Future<Map<String, dynamic>> updateBankingInfo(String vendorId, String bankAccount);
  Future<Map<String, dynamic>> getAnalytics(String vendorId, String startDate, String endDate);
  Future<bool> toggleShopStatus(String vendorId, bool isOpen);
  Future<Map<String, dynamic>> getVerificationStatus(String vendorId);
  Future<void> submitForVerification(String vendorId);
}

/// Implementation of vendor remote data source
class VendorRemoteDataSourceImpl implements VendorRemoteDataSource {
  final Dio dio;

  VendorRemoteDataSourceImpl({required this.dio});

  @override
  Future<Map<String, dynamic>> getVendorById(String vendorId) async {
    try {
      final response = await dio.get('/vendors/$vendorId');
      return response.data;
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  @override
  Future<Map<String, dynamic>> getCurrentVendor() async {
    try {
      final response = await dio.get('/vendors/me');
      return response.data;
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  @override
  Future<Map<String, dynamic>> updateVendor(Map<String, dynamic> vendorData) async {
    try {
      final response = await dio.put('/vendors/me', data: vendorData);
      return response.data;
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  @override
  Future<Map<String, dynamic>> getDashboardData(String vendorId) async {
    try {
      final response = await dio.get('/vendors/$vendorId/dashboard');
      return response.data;
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  @override
  Future<Map<String, dynamic>> updateVendorStatus(String vendorId, String status) async {
    try {
      final response = await dio.patch('/vendors/$vendorId/status', data: {'status': status});
      return response.data;
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  @override
  Future<String> uploadDocument(String vendorId, String filePath, String documentType) async {
    try {
      final formData = FormData.fromMap({
        'document': await MultipartFile.fromFile(filePath),
        'type': documentType,
      });
      
      final response = await dio.post('/vendors/$vendorId/documents', data: formData);
      return response.data['url'];
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  @override
  Future<Map<String, dynamic>> updateBankingInfo(String vendorId, String bankAccount) async {
    try {
      final response = await dio.patch('/vendors/$vendorId/banking', data: {'bankAccount': bankAccount});
      return response.data;
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  @override
  Future<Map<String, dynamic>> getAnalytics(String vendorId, String startDate, String endDate) async {
    try {
      final response = await dio.get('/vendors/$vendorId/analytics', queryParameters: {
        'startDate': startDate,
        'endDate': endDate,
      });
      return response.data;
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  @override
  Future<bool> toggleShopStatus(String vendorId, bool isOpen) async {
    try {
      final response = await dio.patch('/vendors/$vendorId/shop-status', data: {'isOpen': isOpen});
      return response.data['isOpen'];
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  @override
  Future<Map<String, dynamic>> getVerificationStatus(String vendorId) async {
    try {
      final response = await dio.get('/vendors/$vendorId/verification');
      return response.data;
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  @override
  Future<void> submitForVerification(String vendorId) async {
    try {
      await dio.post('/vendors/$vendorId/verification/submit');
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  Exception _handleDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return Exception('Connection timeout. Please check your internet connection.');
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final message = e.response?.data?['message'] ?? 'Unknown error occurred';
        return Exception('Server error ($statusCode): $message');
      case DioExceptionType.cancel:
        return Exception('Request was cancelled');
      case DioExceptionType.unknown:
        return Exception('Network error. Please check your internet connection.');
      default:
        return Exception('An unexpected error occurred');
    }
  }
} 