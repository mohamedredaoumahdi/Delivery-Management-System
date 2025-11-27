import 'package:dio/dio.dart';
import 'models/user_model.dart';

class UserService {
  final Dio _dio;

  UserService(this._dio);

  Future<List<UserModel>> getUsers() async {
    try {
      final response = await _dio.get('/admin/users');
      
      if (response.data['status'] == 'success') {
        final List<dynamic> usersData = response.data['data'];
        return usersData.map((json) => UserModel.fromJson(json)).toList();
      }
      
      throw Exception('Failed to load users');
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('Failed to load users: ${e.toString()}');
    }
  }

  Future<UserModel> getUserById(String id) async {
    try {
      final response = await _dio.get('/admin/users/$id');
      
      if (response.data['status'] == 'success') {
        return UserModel.fromJson(response.data['data']);
      }
      
      throw Exception('Failed to load user');
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('Failed to load user: ${e.toString()}');
    }
  }

  Future<UserModel> updateUser(String id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put('/admin/users/$id', data: data);
      
      if (response.data['status'] == 'success') {
        return UserModel.fromJson(response.data['data']);
      }
      
      throw Exception('Failed to update user');
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('Failed to update user: ${e.toString()}');
    }
  }

  Future<void> deleteUser(String id) async {
    try {
      final response = await _dio.delete('/admin/users/$id');
      
      if (response.data['status'] != 'success') {
        throw Exception('Failed to delete user');
      }
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('Failed to delete user: ${e.toString()}');
    }
  }

  Future<UserModel> createUser(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/admin/users', data: data);

      if (response.data['status'] == 'success') {
        return UserModel.fromJson(response.data['data']);
      }

      throw Exception('Failed to create user');
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('Failed to create user: ${e.toString()}');
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
          return 'User not found';
        case 500:
          return 'Server error. Please try again later.';
        default:
          return 'Something went wrong. Please try again.';
      }
    }
    
    return 'Network error. Please check your connection.';
  }
}

