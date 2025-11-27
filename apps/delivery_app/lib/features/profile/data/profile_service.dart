import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileService {
  final Dio _dio;
  final SharedPreferences _prefs;

  ProfileService(this._dio, this._prefs);

  Future<Map<String, dynamic>> getProfile() async {
    print('🚀 ProfileService: Starting getProfile request');
    try {
      print('📡 ProfileService: Making GET request to /users/profile');
      final response = await _dio.get('/users/profile');
      print('📥 ProfileService: Response status: ${response.statusCode}');
      print('📥 ProfileService: Response data: ${response.data}');
      
      if (response.data['status'] == 'success') {
        print('✅ ProfileService: Profile loaded successfully');
        return response.data['data'];
      } else {
        print('❌ ProfileService: Failed to load profile - response status is not success');
        throw Exception('Failed to load profile');
      }
    } on DioException catch (e) {
      print('❌ ProfileService: DioException in getProfile');
      print('❌ ProfileService: Status code: ${e.response?.statusCode}');
      print('❌ ProfileService: Response data: ${e.response?.data}');
      print('❌ ProfileService: Error message: ${e.message}');
      throw Exception('Failed to load profile: ${e.message}');
    } catch (e) {
      print('❌ ProfileService: Unexpected error in getProfile: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateProfile({
    String? name,
    String? phone,
    String? vehicleType,
    String? licenseNumber,
  }) async {
    print('🚀 ProfileService: Starting updateProfile request');
    try {
      final data = <String, dynamic>{};
      if (name != null) data['name'] = name;
      if (phone != null) data['phone'] = phone;
      if (vehicleType != null) data['vehicleType'] = vehicleType;
      if (licenseNumber != null) data['licenseNumber'] = licenseNumber;

      print('📡 ProfileService: Making PUT request to /users/profile');
      final response = await _dio.put('/users/profile', data: data);
      print('📥 ProfileService: Response status: ${response.statusCode}');
      print('📥 ProfileService: Response data: ${response.data}');
      
      if (response.data['status'] == 'success') {
        print('✅ ProfileService: Profile updated successfully');
        return response.data['data'];
      } else {
        print('❌ ProfileService: Failed to update profile - response status is not success');
        throw Exception('Failed to update profile');
      }
    } on DioException catch (e) {
      print('❌ ProfileService: DioException in updateProfile');
      print('❌ ProfileService: Status code: ${e.response?.statusCode}');
      print('❌ ProfileService: Response data: ${e.response?.data}');
      print('❌ ProfileService: Error message: ${e.message}');
      throw Exception('Failed to update profile: ${e.message}');
    } catch (e) {
      print('❌ ProfileService: Unexpected error in updateProfile: $e');
      rethrow;
    }
  }

  Future<void> logout() async {
    print('🚀 ProfileService: Starting logout');
    try {
      // Clear tokens from storage
      print('🔑 ProfileService: Clearing tokens from storage');
      await _prefs.remove('accessToken');
      await _prefs.remove('refreshToken');
      await _prefs.remove('userId');
      await _prefs.remove('userRole');
      await _prefs.remove('userName');
      
      // Call logout API endpoint
      print('📡 ProfileService: Making POST request to /auth/logout');
      await _dio.post('/auth/logout');
      print('✅ ProfileService: Logout successful');
    } catch (e) {
      print('❌ ProfileService: Error during logout: $e');
      // Still clear tokens even if API call fails
      await _prefs.remove('accessToken');
      await _prefs.remove('refreshToken');
      await _prefs.remove('userId');
      await _prefs.remove('userRole');
      await _prefs.remove('userName');
      rethrow;
    }
  }
} 