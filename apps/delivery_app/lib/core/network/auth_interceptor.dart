import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthInterceptor extends Interceptor {
  final SharedPreferences _prefs;

  AuthInterceptor(this._prefs);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    print('🌐 AuthInterceptor: Intercepting ${options.method} request to ${options.path}');
    
    // Get the access token from storage
    final accessToken = _prefs.getString('accessToken');
    final userId = _prefs.getString('userId');
    final userRole = _prefs.getString('userRole');
    
    print('🔐 AuthInterceptor: Token exists: ${accessToken != null && accessToken.isNotEmpty}');
    print('👤 AuthInterceptor: User ID: $userId');
    print('🎭 AuthInterceptor: User Role: $userRole');
    
    if (accessToken != null && accessToken.isNotEmpty) {
      // Add Authorization header to all requests
      options.headers['Authorization'] = 'Bearer $accessToken';
      print('✅ AuthInterceptor: Added auth token to ${options.method} ${options.path}');
      print('🔐 AuthInterceptor: Token preview: ${accessToken.substring(0, 20)}...');
    } else {
      print('⚠️ AuthInterceptor: No access token found for ${options.method} ${options.path}');
    }
    
    print('📡 AuthInterceptor: Forwarding request to backend');
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Handle 401 Unauthorized responses
    if (err.response?.statusCode == 401) {
      print('🚫 AuthInterceptor: 401 Unauthorized - Token may be expired');
      
      // Try to refresh token
      final refreshToken = _prefs.getString('refreshToken');
      if (refreshToken != null && refreshToken.isNotEmpty) {
        try {
          // Create new Dio instance to avoid infinite recursion
          final dio = Dio();
          dio.options.baseUrl = err.requestOptions.baseUrl;
          
          final response = await dio.post('/auth/refresh', data: {
            'refreshToken': refreshToken,
          });
          
          if (response.data['status'] == 'success') {
            final newAccessToken = response.data['data']['accessToken'];
            await _prefs.setString('accessToken', newAccessToken);
            
            print('✅ AuthInterceptor: Token refreshed successfully');
            
            // Retry the original request with new token
            final retryOptions = err.requestOptions;
            retryOptions.headers['Authorization'] = 'Bearer $newAccessToken';
            
            final retryResponse = await Dio().fetch(retryOptions);
            handler.resolve(retryResponse);
            return;
          }
        } catch (e) {
          print('❌ AuthInterceptor: Token refresh failed: $e');
        }
      }
      
      // Clear tokens and redirect to login
      await _prefs.remove('accessToken');
      await _prefs.remove('refreshToken');
      print('🔓 AuthInterceptor: Cleared tokens, user needs to login again');
    }
    
    handler.next(err);
  }
} 