import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final Dio _dio;
  final SharedPreferences _prefs;

  AuthService(this._dio, this._prefs);

  Future<bool> login(String email, String password) async {
    try {
      final response = await _dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });

      if (response.data['status'] == 'success') {
        final data = response.data['data'];
        final accessToken = data['accessToken'];
        final refreshToken = data['refreshToken'];
        final user = data['user'];

        // Check if user has DELIVERY role
        if (user['role'] != 'DELIVERY') {
          throw Exception('Access denied. Delivery role required.');
        }

        // Store tokens
        await _prefs.setString('auth_token', accessToken);
        await _prefs.setString('refresh_token', refreshToken);
        await _prefs.setString('user_data', response.data.toString());

        return true;
      } else {
        throw Exception('Login failed');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Invalid email or password');
      } else {
        throw Exception('Login failed: ${e.message}');
      }
    }
  }

  Future<void> logout() async {
    await _prefs.remove('auth_token');
    await _prefs.remove('refresh_token');
    await _prefs.remove('user_data');
  }

  Future<bool> isLoggedIn() async {
    final token = _prefs.getString('auth_token');
    return token != null && token.isNotEmpty;
  }

  String? getToken() {
    return _prefs.getString('auth_token');
  }
} 