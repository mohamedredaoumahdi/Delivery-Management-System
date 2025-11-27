import 'package:dio/dio.dart';
import 'models/shop_model.dart';

class ShopService {
  final Dio _dio;

  ShopService(this._dio);

  Future<List<ShopModel>> getShops() async {
    try {
      final response = await _dio.get('/admin/shops');
      
      if (response.data['status'] == 'success') {
        final List<dynamic> shopsData = response.data['data'];
        return shopsData.map((json) => ShopModel.fromJson(json)).toList();
      }
      
      throw Exception('Failed to load shops');
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('Failed to load shops: ${e.toString()}');
    }
  }

  Future<ShopModel> createShop(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/admin/shops', data: data);
      
      if (response.data['status'] == 'success') {
        return ShopModel.fromJson(response.data['data']);
      }
      
      throw Exception('Failed to create shop');
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('Failed to create shop: ${e.toString()}');
    }
  }

  Future<ShopModel> getShopById(String id) async {
    try {
      final response = await _dio.get('/admin/shops/$id');
      
      if (response.data['status'] == 'success') {
        return ShopModel.fromJson(response.data['data']);
      }
      
      throw Exception('Failed to load shop');
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('Failed to load shop: ${e.toString()}');
    }
  }

  Future<ShopModel> updateShop(String id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put('/admin/shops/$id', data: data);
      
      if (response.data['status'] == 'success') {
        return ShopModel.fromJson(response.data['data']);
      }
      
      throw Exception('Failed to update shop');
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('Failed to update shop: ${e.toString()}');
    }
  }

  Future<void> deleteShop(String id) async {
    try {
      final response = await _dio.delete('/admin/shops/$id');
      
      if (response.data['status'] != 'success') {
        throw Exception('Failed to delete shop');
      }
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('Failed to delete shop: ${e.toString()}');
    }
  }

  // Vendor approval management
  Future<ShopModel> approveVendor(String id, {String? reason}) async {
    try {
      final response = await _dio.post(
        '/admin/shops/$id/approve',
        data: reason != null ? {'reason': reason} : {},
      );
      
      if (response.data['status'] == 'success') {
        return ShopModel.fromJson(response.data['data']);
      }
      
      throw Exception('Failed to approve vendor');
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('Failed to approve vendor: ${e.toString()}');
    }
  }

  Future<ShopModel> rejectVendor(String id, String reason) async {
    try {
      final response = await _dio.post(
        '/admin/shops/$id/reject',
        data: {'reason': reason},
      );
      
      if (response.data['status'] == 'success') {
        return ShopModel.fromJson(response.data['data']);
      }
      
      throw Exception('Failed to reject vendor');
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('Failed to reject vendor: ${e.toString()}');
    }
  }

  Future<ShopModel> suspendVendor(String id, String reason) async {
    try {
      final response = await _dio.post(
        '/admin/shops/$id/suspend',
        data: {'reason': reason},
      );
      
      if (response.data['status'] == 'success') {
        return ShopModel.fromJson(response.data['data']);
      }
      
      throw Exception('Failed to suspend vendor');
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('Failed to suspend vendor: ${e.toString()}');
    }
  }

  // Vendor performance tracking
  Future<Map<String, dynamic>> getVendorPerformance(String id) async {
    try {
      final response = await _dio.get('/admin/shops/$id/performance');
      
      if (response.data['status'] == 'success') {
        return Map<String, dynamic>.from(response.data['data']);
      }
      
      throw Exception('Failed to load vendor performance');
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('Failed to load vendor performance: ${e.toString()}');
    }
  }

  String _handleDioError(DioException e) {
    if (e.response != null) {
      final statusCode = e.response!.statusCode;
      final data = e.response!.data;
      
      switch (statusCode) {
        case 400:
          return data['message'] ?? 'Invalid request';
        case 401:
          return 'Unauthorized. Please login again.';
        case 403:
          return 'Access denied';
        case 404:
          return 'Shop not found';
        case 500:
          return 'Server error. Please try again later.';
        default:
          return 'Something went wrong. Please try again.';
      }
    }
    
    return 'Network error. Please check your connection.';
  }
}

