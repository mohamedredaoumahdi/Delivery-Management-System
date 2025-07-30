import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final Dio _dio;
  final SharedPreferences _prefs;

  AuthService(this._dio, this._prefs);

  Future<bool> login(String email, String password) async {
    print('🚀 AuthService: Starting login attempt for: $email');
    
    try {
      print('📡 AuthService: Making POST request to /auth/login');
      final response = await _dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });

      print('📥 AuthService: Response status: ${response.statusCode}');
      print('📥 AuthService: Response data: ${response.data}');

      if (response.data['status'] == 'success') {
        final data = response.data['data'];
        final accessToken = data['accessToken'];
        final refreshToken = data['refreshToken'];
        final user = data['user'];

        print('👤 AuthService: User data received: $user');

        // Check if user has DELIVERY role
        if (user['role'] != 'DELIVERY') {
          print('❌ AuthService: Access denied - user role is ${user['role']}, expected DELIVERY');
          throw Exception('Access denied. Delivery role required.');
        }

        print('✅ AuthService: Role validation passed - user has DELIVERY role');

        // Store tokens with correct keys for AuthInterceptor
        await _prefs.setString('accessToken', accessToken);
        await _prefs.setString('refreshToken', refreshToken);
        await _prefs.setString('userId', user['id']);
        await _prefs.setString('userRole', user['role']);
        await _prefs.setString('userName', user['name'] ?? 'Delivery Driver');
        
        print('✅ AuthService: Login successful for ${user['name']} (${user['role']})');
        print('🔐 AuthService: Stored access token: ${accessToken.substring(0, 20)}...');
        print('💾 AuthService: All tokens and user data stored successfully');

        return true;
      } else {
        print('❌ AuthService: Login failed - response status is not success');
        throw Exception('Login failed');
      }
    } on DioException catch (e) {
      print('❌ AuthService: DioException occurred');
      print('❌ AuthService: Status code: ${e.response?.statusCode}');
      print('❌ AuthService: Response data: ${e.response?.data}');
      print('❌ AuthService: Error message: ${e.message}');
      
      if (e.response?.statusCode == 401) {
        throw Exception('Invalid email or password');
      } else {
        throw Exception('Login failed: ${e.message}');
      }
    } catch (e) {
      print('❌ AuthService: Unexpected error: $e');
      rethrow;
    }
  }

  Future<void> logout() async {
    await _prefs.remove('accessToken');
    await _prefs.remove('refreshToken');
    await _prefs.remove('userId');
    await _prefs.remove('userRole');
    await _prefs.remove('userName');
    print('🔓 AuthService: Logged out and cleared all tokens');
  }

  String? getCurrentUserRole() {
    return _prefs.getString('userRole');
  }

  Future<bool> isLoggedIn() async {
    final accessToken = _prefs.getString('accessToken');
    return accessToken != null && accessToken.isNotEmpty;
  }
} 