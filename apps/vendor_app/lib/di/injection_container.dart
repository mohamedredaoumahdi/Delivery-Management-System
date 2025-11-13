import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

// Features
import '../features/auth/presentation/bloc/auth_bloc.dart';
import '../features/dashboard/presentation/bloc/dashboard_bloc.dart';
import '../features/menu/presentation/bloc/menu_bloc.dart';
import '../features/orders/presentation/bloc/orders_bloc.dart';
import '../features/profile/presentation/bloc/profile_bloc.dart';
import '../features/analytics/presentation/bloc/analytics_bloc.dart';

final GetIt sl = GetIt.instance;

Future<void> initializeDependencies() async {
  // External dependencies
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton<SharedPreferences>(() => sharedPreferences);
  
  sl.registerLazySingleton<Connectivity>(() => Connectivity());
  
  // Dio
  sl.registerLazySingleton<Dio>(() {
    final dio = Dio();
    dio.options = BaseOptions(
      baseUrl: 'http://localhost:3000/api',
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );
    
    // Add auth interceptor with token refresh capability
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        // Add auth token if available
        final token = sl<SharedPreferences>().getString('access_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        // Handle 401 unauthorized with token refresh
        if (error.response?.statusCode == 401) {
          final refreshToken = sl<SharedPreferences>().getString('refresh_token');
          
          if (refreshToken != null) {
            try {
              // Attempt to refresh token
              final refreshResponse = await Dio().post(
                'http://localhost:3000/api/auth/refresh',
                data: {'refreshToken': refreshToken},
              );
              
              if (refreshResponse.statusCode == 200) {
                final newAccessToken = refreshResponse.data['data']['accessToken'];
                final newRefreshToken = refreshResponse.data['data']['refreshToken'];
                
                // Store new tokens
                await sl<SharedPreferences>().setString('access_token', newAccessToken);
                await sl<SharedPreferences>().setString('refresh_token', newRefreshToken);
                
                // Retry the original request with new token
                error.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
                final response = await dio.fetch(error.requestOptions);
                handler.resolve(response);
                return;
              }
            } catch (e) {
              print('Token refresh failed: $e');
            }
          }
          
          // If refresh fails or no refresh token, clear tokens and force re-login
          await sl<SharedPreferences>().remove('access_token');
          await sl<SharedPreferences>().remove('refresh_token');
        }
        handler.next(error);
      },
    ));
    
    // Add logging interceptor
    dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      requestHeader: true,
      responseHeader: true,
    ));
    
    return dio;
  });
  
  // Services (clean backend integration)
  sl.registerLazySingleton<AuthService>(
    () => AuthService(sl<SharedPreferences>(), sl<Dio>()),
  );
  
  sl.registerLazySingleton<VendorService>(
    () => VendorService(sl<Dio>()),
  );
  
  sl.registerLazySingleton<MenuService>(
    () => MenuService(sl<Dio>()),
  );
  
  sl.registerLazySingleton<OrderService>(
    () => OrderService(sl<Dio>()),
  );
  
  // Blocs with service dependencies
  sl.registerFactory(() => AuthBloc(
    authService: sl<AuthService>(),
  ));
  
  sl.registerFactory(() => DashboardBloc(
    vendorService: sl<VendorService>(),
  ));
  
  sl.registerFactory(() => MenuBloc(
    menuService: sl<MenuService>(),
  ));
  
  sl.registerFactory(() => OrdersBloc(
    orderService: sl<OrderService>(),
  ));
  
  sl.registerFactory(() => ProfileBloc(
    authService: sl<AuthService>(),
  ));
  
  sl.registerFactory(() => AnalyticsBloc(
    vendorService: sl<VendorService>(),
    orderService: sl<OrderService>(),
    menuService: sl<MenuService>(),
  ));
}

// Authentication service with clean backend integration
class AuthService {
  final SharedPreferences _sharedPreferences;
  final Dio _dio;
  
  AuthService(this._sharedPreferences, this._dio);
  
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });
      
      // Store both access and refresh tokens from backend response
      if (response.data['data']['accessToken'] != null) {
        await _sharedPreferences.setString('access_token', response.data['data']['accessToken']);
      }
      if (response.data['data']['refreshToken'] != null) {
        await _sharedPreferences.setString('refresh_token', response.data['data']['refreshToken']);
      }
      
      return {
        'success': true,
        'user': response.data['data']['user'],
      };
    } on DioException catch (e) {
      String errorMessage = _handleDioError(e);
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('Something went wrong. Please check your internet connection and try again.');
    }
  }
  
  Future<Map<String, dynamic>> register(Map<String, String> data) async {
    try {
      // Clear any existing auth data first
      await _sharedPreferences.remove('access_token');
      await _sharedPreferences.remove('refresh_token');
      
      final response = await _dio.post('/auth/register', data: {
        'email': data['email'],
        'password': data['password'],
        'confirmPassword': data['password'],
        'name': data['name'],
        'phone': data['phone'],
        'role': 'VENDOR',
      });
      
      // Store both access and refresh tokens from backend response
      if (response.data['data']['accessToken'] != null) {
        await _sharedPreferences.setString('access_token', response.data['data']['accessToken']);
      }
      if (response.data['data']['refreshToken'] != null) {
        await _sharedPreferences.setString('refresh_token', response.data['data']['refreshToken']);
      }
      
      return {
        'success': true,
        'user': response.data['data']['user'],
      };
    } on DioException catch (e) {
      String errorMessage = _handleDioError(e);
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('Registration failed. Please check your internet connection and try again.');
    }
  }
  
  Future<void> logout() async {
    try {
      // Send refresh token to logout endpoint
      final refreshToken = _sharedPreferences.getString('refresh_token');
      if (refreshToken != null) {
        await _dio.post('/auth/logout', data: {'refreshToken': refreshToken});
      }
    } catch (e) {
      // Continue with logout even if API call fails
      print('Logout API call failed, but continuing with local logout: $e');
    } finally {
      // Always clear both tokens locally
      await _sharedPreferences.remove('access_token');
      await _sharedPreferences.remove('refresh_token');
    }
  }
  
  Future<Map<String, dynamic>?> getCurrentUser() async {
    // Check if token exists
    final token = _sharedPreferences.getString('access_token');
    if (token == null) {
      return null;
    }
    
    try {
      final response = await _dio.get('/auth/me');
      return response.data['data'];
    } on DioException catch (e) {
      if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
        // Token is invalid, clear it
        await _sharedPreferences.remove('access_token');
        return null;
      }
      // For other errors, still clear token and return null to force re-login
      await _sharedPreferences.remove('access_token');
      throw Exception('Unable to load your profile. Please login again.');
    } catch (e) {
      // Network or other errors
      await _sharedPreferences.remove('access_token');
      throw Exception('Network error. Please check your connection and try again.');
    }
  }

  String _handleDioError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout || 
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return 'Connection timeout. Please check your internet connection and try again.';
    }
    
    if (e.type == DioExceptionType.connectionError) {
      return 'Unable to connect to the server. Please check your internet connection.';
    }
    
    if (e.response != null) {
      final statusCode = e.response!.statusCode;
      final data = e.response!.data;
      
      switch (statusCode) {
        case 400:
          if (data != null && data['message'] != null) {
            return data['message'];
          }
          return 'Invalid request. Please check your input and try again.';
        case 401:
          return 'Invalid email or password. Please check your credentials.';
        case 403:
          return 'Access denied. Your account may be suspended.';
        case 404:
          return 'Account not found. Please check your email or create a new account.';
        case 409:
          return 'An account with this email already exists. Please use a different email or try logging in.';
        case 422:
          if (data != null && data['message'] != null) {
            return data['message'];
          }
          return 'Please check your input and try again.';
        case 500:
          return 'Server error. Please try again later.';
        default:
          return 'Something went wrong. Please try again later.';
      }
    }
    
    return 'Network error. Please check your connection and try again.';
  }
}

// Vendor service with clean backend integration
class VendorService {
  final Dio _dio;
  
  VendorService(this._dio);
  
  Future<Map<String, dynamic>> getDashboardData() async {
    try {
      final response = await _dio.get('/vendor/shop');
      return response.data['data'];
    } on DioException catch (e) {
      String errorMessage = _handleDioError(e);
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('Unable to load dashboard data. Please check your connection and try again.');
    }
  }
  
  Future<Map<String, dynamic>> createShop(Map<String, dynamic> shopData) async {
    try {
      final response = await _dio.post('/vendor/shop', data: shopData);
      return response.data;
    } on DioException catch (e) {
      String errorMessage = _handleDioError(e);
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('Failed to create shop. Please check your connection and try again.');
    }
  }
  
  Future<Map<String, dynamic>> getAnalytics({String? period}) async {
    try {
      final response = await _dio.get('/vendor/analytics/sales', queryParameters: {
        if (period != null) 'period': period,
      });
      return response.data;
    } on DioException catch (e) {
      String errorMessage = _handleDioError(e);
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('Unable to load analytics data. Please check your connection and try again.');
    }
  }

  String _handleDioError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout || 
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return 'Connection timeout. Please check your internet connection and try again.';
    }
    
    if (e.type == DioExceptionType.connectionError) {
      return 'Unable to connect to the server. Please check your internet connection.';
    }
    
    if (e.response != null) {
      final statusCode = e.response!.statusCode;
      final data = e.response!.data;
      
      switch (statusCode) {
        case 401:
          return 'Session expired. Please login again.';
        case 403:
          return 'Access denied. You may not have permission to perform this action.';
        case 404:
          return 'Shop not found. Please create your shop first.';
        case 500:
          return 'Server error. Please try again later.';
        default:
          if (data != null && data['message'] != null) {
            return data['message'];
          }
          return 'Something went wrong. Please try again later.';
      }
    }
    
    return 'Network error. Please check your connection and try again.';
  }
}

// Menu service with clean backend integration
class MenuService {
  final Dio _dio;
  
  MenuService(this._dio);
  
  Future<List<Map<String, dynamic>>> getMenuItems() async {
    try {
      final response = await _dio.get('/vendor/products');
      
      // Handle both response formats
      if (response.data is List) {
        return List<Map<String, dynamic>>.from(response.data);
      } else if (response.data is Map && response.data['data'] is List) {
        return List<Map<String, dynamic>>.from(response.data['data']);
      } else {
        return [];
      }
    } on DioException catch (e) {
      String errorMessage = _handleDioError(e);
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('Unable to load menu items. Please check your connection and try again.');
    }
  }
  
  Future<Map<String, dynamic>> createMenuItem(Map<String, dynamic> data) async {
    try {
      final requestData = {
        'name': data['name'],
        'description': data['description'],
        'price': data['price'],
        'categoryName': data['categoryName'] ?? 'Main Course',
        'inStock': data['inStock'] ?? true,
      };
      
      // Add preparation time if provided
      if (data['preparationTime'] != null) {
        requestData['preparationTime'] = data['preparationTime'];
      }
      
      print('Creating menu item with data: $requestData');
      
      final response = await _dio.post('/vendor/products', data: requestData);
      
      print('Menu item creation response: ${response.data}');
      
      // Handle both response formats
      if (response.data is Map && response.data['data'] != null) {
        return response.data['data'];
      } else {
        return response.data;
      }
    } on DioException catch (e) {
      print('DioException creating menu item: ${e.message}');
      print('Response data: ${e.response?.data}');
      String errorMessage = _handleDioError(e);
      throw Exception(errorMessage);
    } catch (e) {
      print('Exception creating menu item: $e');
      throw Exception('Failed to create menu item. Please check your connection and try again.');
    }
  }
  
  Future<String> _getOrCreateCategory(String categoryName) async {
    try {
      // Map category names to the specific IDs we created in the database
      final categoryId = _getCategoryIdByName(categoryName);
      print('Using category ID: $categoryId for category: $categoryName');
      return categoryId;
    } catch (e) {
      print('Error in category management: $e');
      // Fallback to main course category
      return 'cat-12345678-1234-1234-1234-123456789012';
    }
  }
  
  String _getCategoryIdByName(String categoryName) {
    // Map category names to the specific IDs we created in the database
    switch (categoryName.toLowerCase()) {
      case 'main course':
        return 'cat-12345678-1234-1234-1234-123456789012';
      case 'salads':
        return 'cat-87654321-4321-4321-4321-210987654321';
      case 'beverages':
        return 'cat-11111111-1111-1111-1111-111111111111';
      case 'desserts':
        return 'cat-22222222-2222-2222-2222-222222222222';
      case 'appetizers':
        return 'cat-12345678-1234-1234-1234-123456789012'; // Use main course for appetizers
      case 'sides':
        return 'cat-12345678-1234-1234-1234-123456789012'; // Use main course for sides
      default:
        // Default to main course category
        return 'cat-12345678-1234-1234-1234-123456789012';
    }
  }
  
  Future<Map<String, dynamic>> updateMenuItem(String id, Map<String, dynamic> data) async {
    try {
      final requestData = {
        'name': data['name'],
        'description': data['description'],
        'price': data['price'],
        'categoryName': data['categoryName'] ?? 'Main Course',
        'inStock': data['inStock'] ?? true,
      };
      
      // Add preparation time if provided
      if (data['preparationTime'] != null) {
        requestData['preparationTime'] = data['preparationTime'];
      }
      
      final response = await _dio.put('/vendor/products/$id', data: requestData);
      
      // Handle both response formats
      if (response.data is Map && response.data['data'] != null) {
        return response.data['data'];
      } else {
        return response.data;
      }
    } on DioException catch (e) {
      String errorMessage = _handleDioError(e);
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('Failed to update menu item. Please check your connection and try again.');
    }
  }
  
  Future<void> deleteMenuItem(String id) async {
    try {
      await _dio.delete('/vendor/products/$id');
    } on DioException catch (e) {
      String errorMessage = _handleDioError(e);
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('Failed to delete menu item. Please check your connection and try again.');
    }
  }
  
  Future<Map<String, dynamic>> toggleAvailability(String id, bool isAvailable) async {
    try {
      // Use PUT to update the product with availability fields
      final response = await _dio.put('/vendor/products/$id', data: {
        'inStock': isAvailable,
        'isActive': isAvailable,
      });
      
      print('Availability toggle response: ${response.data}');
      
      // Handle the response format {status: 'success', data: {...}}
      if (response.data is Map && response.data['data'] != null) {
        return response.data['data'];
      } else {
        return response.data;
      }
    } on DioException catch (e) {
      String errorMessage = _handleDioError(e);
      throw Exception(errorMessage);
    } catch (e) {
      print('Unexpected error: $e');
      throw Exception('Failed to update item availability. Please check your connection and try again.');
    }
  }

  String _handleDioError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout || 
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return 'Connection timeout. Please check your internet connection and try again.';
    }
    
    if (e.type == DioExceptionType.connectionError) {
      return 'Unable to connect to the server. Please check your internet connection.';
    }
    
    if (e.response != null) {
      final statusCode = e.response!.statusCode;
      final data = e.response!.data;
      
      switch (statusCode) {
        case 401:
          return 'Session expired. Please login again.';
        case 403:
          return 'Access denied. You may not have permission to perform this action.';
        case 404:
          return 'Menu item not found.';
        case 400:
          if (data != null && data['message'] != null) {
            return data['message'];
          }
          return 'Invalid request. Please check your input and try again.';
        case 500:
          return 'Server error. Please try again later.';
        default:
          if (data != null && data['message'] != null) {
            return data['message'];
          }
          return 'Something went wrong. Please try again later.';
      }
    }
    
    return 'Network error. Please check your connection and try again.';
  }
}

// Order service with clean backend integration
class OrderService {
  final Dio _dio;
  
  OrderService(this._dio);
  
  Future<List<Map<String, dynamic>>> getOrders({String? status}) async {
    try {
      final response = await _dio.get('/vendor/orders', queryParameters: {
        if (status != null) 'status': status,
      });
      
      // Handle both response formats:
      // 1. {"status":"success","data":[]} - structured response
      // 2. [] - direct array response
      if (response.data is List) {
        return List<Map<String, dynamic>>.from(response.data);
      } else if (response.data is Map && response.data['data'] is List) {
        return List<Map<String, dynamic>>.from(response.data['data']);
      } else {
        return [];
      }
    } on DioException catch (e) {
      String errorMessage = _handleDioError(e);
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('Unable to load orders. Please check your connection and try again.');
    }
  }
  
  Future<Map<String, dynamic>> updateOrderStatus(String orderId, String status) async {
    try {
      final response = await _dio.patch('/vendor/orders/$orderId/status', data: {
        'status': status,
      });
      return response.data;
    } on DioException catch (e) {
      String errorMessage = _handleDioError(e);
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('Failed to update order status. Please check your connection and try again.');
    }
  }
  
  Future<Map<String, dynamic>> getOrderStats() async {
    try {
      final response = await _dio.get('/vendor/orders/stats');
      return response.data;
    } on DioException catch (e) {
      String errorMessage = _handleDioError(e);
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('Unable to load order statistics. Please check your connection and try again.');
    }
  }

  String _handleDioError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout || 
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return 'Connection timeout. Please check your internet connection and try again.';
    }
    
    if (e.type == DioExceptionType.connectionError) {
      return 'Unable to connect to the server. Please check your internet connection.';
    }
    
    if (e.response != null) {
      final statusCode = e.response!.statusCode;
      final data = e.response!.data;
      
      switch (statusCode) {
        case 401:
          return 'Session expired. Please login again.';
        case 403:
          return 'Access denied. You may not have permission to perform this action.';
        case 404:
          return 'Order not found.';
        case 400:
          if (data != null && data['message'] != null) {
            return data['message'];
          }
          return 'Invalid request. Please check your input and try again.';
        case 500:
          return 'Server error. Please try again later.';
        default:
          if (data != null && data['message'] != null) {
            return data['message'];
          }
          return 'Something went wrong. Please try again later.';
      }
    }
    
    return 'Network error. Please check your connection and try again.';
  }
} 