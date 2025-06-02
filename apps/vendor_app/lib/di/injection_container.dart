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
      baseUrl: 'http://localhost:8000/api',
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );
    
    // Add auth interceptor
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        // Add auth token if available
        final token = sl<SharedPreferences>().getString('auth_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) {
        // Handle 401 unauthorized
        if (error.response?.statusCode == 401) {
          // Clear token and redirect to login
          sl<SharedPreferences>().remove('auth_token');
          // TODO: Navigate to login page
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
  ));
}

// Authentication service with clean backend integration
class AuthService {
  final SharedPreferences _sharedPreferences;
  final Dio _dio;
  
  AuthService(this._sharedPreferences, this._dio);
  
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    
    // Store auth token from backend response
    if (response.data['data']['accessToken'] != null) {
      await _sharedPreferences.setString('auth_token', response.data['data']['accessToken']);
    }
    
    return {
      'success': true,
      'user': response.data['data']['user'],
    };
  }
  
  Future<Map<String, dynamic>> register(Map<String, String> data) async {
    final response = await _dio.post('/auth/register', data: {
      'email': data['email'],
      'password': data['password'],
      'confirmPassword': data['password'],
      'name': data['name'],
      'phone': data['phone'],
      'role': 'VENDOR',
    });
    
    // Store auth token from backend response
    if (response.data['data']['accessToken'] != null) {
      await _sharedPreferences.setString('auth_token', response.data['data']['accessToken']);
    }
    
    return {
      'success': true,
      'user': response.data['data']['user'],
    };
  }
  
  Future<void> logout() async {
    await _dio.post('/auth/logout');
    await _sharedPreferences.remove('auth_token');
  }
  
  Future<Map<String, dynamic>?> getCurrentUser() async {
    final response = await _dio.get('/auth/me');
    return response.data['data'];
  }
}

// Vendor service with clean backend integration
class VendorService {
  final Dio _dio;
  
  VendorService(this._dio);
  
  Future<Map<String, dynamic>> getDashboardData() async {
    final response = await _dio.get('/vendor/shop');
    return response.data;
  }
  
  Future<Map<String, dynamic>> createShop(Map<String, dynamic> shopData) async {
    final response = await _dio.post('/vendor/shop', data: shopData);
    return response.data;
  }
  
  Future<Map<String, dynamic>> getAnalytics({String? period}) async {
    final response = await _dio.get('/vendor/analytics/sales', queryParameters: {
      if (period != null) 'period': period,
    });
    return response.data;
  }
}

// Menu service with clean backend integration
class MenuService {
  final Dio _dio;
  
  MenuService(this._dio);
  
  Future<List<Map<String, dynamic>>> getMenuItems() async {
    final response = await _dio.get('/vendor/products');
    return List<Map<String, dynamic>>.from(response.data);
  }
  
  Future<Map<String, dynamic>> createMenuItem(Map<String, dynamic> data) async {
    final response = await _dio.post('/vendor/products', data: data);
    return response.data;
  }
  
  Future<Map<String, dynamic>> updateMenuItem(String id, Map<String, dynamic> data) async {
    final response = await _dio.put('/vendor/products/$id', data: data);
    return response.data;
  }
  
  Future<void> deleteMenuItem(String id) async {
    await _dio.delete('/vendor/products/$id');
  }
  
  Future<Map<String, dynamic>> toggleAvailability(String id, bool isAvailable) async {
    final response = await _dio.patch('/vendor/products/$id', data: {
      'isAvailable': isAvailable,
    });
    return response.data;
  }
}

// Order service with clean backend integration
class OrderService {
  final Dio _dio;
  
  OrderService(this._dio);
  
  Future<List<Map<String, dynamic>>> getOrders({String? status}) async {
    final response = await _dio.get('/vendor/orders', queryParameters: {
      if (status != null) 'status': status,
    });
    return List<Map<String, dynamic>>.from(response.data);
  }
  
  Future<Map<String, dynamic>> updateOrderStatus(String orderId, String status) async {
    final response = await _dio.patch('/vendor/orders/$orderId/status', data: {
      'status': status,
    });
    return response.data;
  }
  
  Future<Map<String, dynamic>> getOrderStats() async {
    final response = await _dio.get('/vendor/orders/stats');
    return response.data;
  }
} 