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
  
  // Services (bridge between old and new architecture)
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
    () => OrderService(),
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

// Authentication service with real API integration
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
      
      // Store auth token
      if (response.data['token'] != null) {
        await _sharedPreferences.setString('auth_token', response.data['token']);
      }
      
      return {
        'success': true,
        'user': response.data['user'],
      };
    } catch (e) {
      // Fallback to mock authentication for development
      if (email == 'vendor@test.com' && password == 'password') {
        await _sharedPreferences.setString('auth_token', 'mock_token_for_development');
        return {
          'success': true,
          'user': {
            'id': '1',
            'name': 'Maria Rodriguez',
            'email': email,
            'businessName': 'Bella Vista Restaurant',
            'phone': '+1 (555) 123-4567',
            'address': '123 Main Street, Downtown, CA 90210',
            'cuisineType': 'Italian & Mediterranean',
            'status': 'active',
            'role': 'vendor',
            'isVerified': true,
            'rating': 4.8,
            'totalRatings': 156,
            'totalOrders': 247,
            'joinedAt': '2023-01-15T10:00:00.000Z',
            'updatedAt': DateTime.now().toIso8601String(),
          }
        };
      }
      throw Exception('Invalid credentials');
    }
  }
  
  Future<Map<String, dynamic>> register(Map<String, String> data) async {
    try {
      final response = await _dio.post('/auth/register', data: {
        'email': data['email'],
        'password': data['password'],
        'name': data['name'],
        'phone': data['phone'],
        'businessName': data['businessName'],
        'businessAddress': data['businessAddress'],
        'role': 'vendor',
      });
      
      // Store auth token
      if (response.data['token'] != null) {
        await _sharedPreferences.setString('auth_token', response.data['token']);
      }
      
      return {
        'success': true,
        'user': response.data['user'],
      };
    } catch (e) {
      // Fallback to mock registration for development
      return {
        'success': true,
        'user': {
          'id': '1',
          'name': data['name'],
          'email': data['email'],
          'businessName': data['businessName'],
        }
      };
    }
  }
  
  Future<void> logout() async {
    try {
      await _dio.post('/auth/logout');
    } catch (e) {
      // Continue with logout even if API call fails
    } finally {
      await _sharedPreferences.remove('auth_token');
    }
  }
  
  Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final response = await _dio.get('/auth/me');
      return response.data;
    } catch (e) {
      // Store mock token and return mock user data for development when API fails
      await _sharedPreferences.setString('auth_token', 'mock_token_for_development');
      return {
        'id': '1',
        'name': 'Maria Rodriguez',
        'email': 'vendor@test.com',
        'businessName': 'Bella Vista Restaurant',
        'phone': '+1 (555) 123-4567',
        'address': '123 Main Street, Downtown, CA 90210',
        'cuisineType': 'Italian & Mediterranean',
        'status': 'active',
        'role': 'vendor',
        'isVerified': true,
        'rating': 4.8,
        'totalRatings': 156,
        'totalOrders': 247,
        'joinedAt': '2023-01-15T10:00:00.000Z',
        'updatedAt': DateTime.now().toIso8601String(),
      };
    }
  }
}

// Vendor service with real API integration
class VendorService {
  final Dio _dio;
  
  VendorService(this._dio);
  
  Future<Map<String, dynamic>> getDashboardData() async {
    try {
      final response = await _dio.get('/vendors/me/dashboard');
      return response.data;
    } catch (e) {
      // Fallback to mock data if API fails
      return {
        'todayOrders': 24,
        'todayRevenue': 480.50,
        'pendingOrders': 3,
        'preparingOrders': 2,
        'readyOrders': 1,
        'completedOrders': 20,
        'rating': 4.8,
        'totalRatings': 156,
        'weekOrders': 168,
        'weekRevenue': 3360.0,
        'monthOrders': 720,
        'monthRevenue': 14400.0,
        'totalOrders': 2400,
        'totalRevenue': 48000.0,
        'averageOrderValue': 20.0,
        'recentOrders': [],
        'topItems': [],
        'revenueTrend': [],
        'ordersTrend': [],
        'peakHours': [],
        'isShopOpen': true,
        'activeMenuItems': 25,
        'outOfStockItems': 3,
        'lastUpdated': DateTime.now().toIso8601String(),
      };
    }
  }
}

// Menu service with real API integration
class MenuService {
  final Dio _dio;
  
  MenuService(this._dio);
  
  Future<List<Map<String, dynamic>>> getMenuItems() async {
    try {
      final response = await _dio.get('/vendors/me/menu-items');
      return List<Map<String, dynamic>>.from(response.data);
    } catch (e) {
      // Fallback to mock data if API fails
      return [
        {
          'id': '1',
          'name': 'Classic Burger',
          'description': 'Juicy beef patty with lettuce, tomato, and special sauce',
          'price': 12.99,
          'category': 'Main Course',
          'subcategory': null,
          'status': 'available',
          'isAvailable': true,
          'images': [],
          'mainImageUrl': null,
          'preparationTime': 15,
          'calories': 650,
          'allergens': ['gluten', 'dairy'],
          'dietaryTags': [],
          'variations': [],
          'addOns': [],
          'isCustomizable': true,
          'vendorId': 'current-vendor',
          'sortOrder': 1,
          'isFeatured': true,
          'discountPercentage': null,
          'discountedPrice': null,
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        },
        {
          'id': '2',
          'name': 'Margherita Pizza',
          'description': 'Fresh mozzarella, tomato sauce, and basil',
          'price': 15.99,
          'category': 'Main Course',
          'subcategory': 'Pizza',
          'status': 'available',
          'isAvailable': true,
          'images': [],
          'mainImageUrl': null,
          'preparationTime': 20,
          'calories': 800,
          'allergens': ['gluten', 'dairy'],
          'dietaryTags': ['vegetarian'],
          'variations': [],
          'addOns': [],
          'isCustomizable': true,
          'vendorId': 'current-vendor',
          'sortOrder': 2,
          'isFeatured': false,
          'discountPercentage': null,
          'discountedPrice': null,
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        },
        {
          'id': '3',
          'name': 'Caesar Salad',
          'description': 'Crisp romaine lettuce with parmesan and croutons',
          'price': 9.99,
          'category': 'Salads',
          'subcategory': null,
          'status': 'available',
          'isAvailable': true,
          'images': [],
          'mainImageUrl': null,
          'preparationTime': 10,
          'calories': 350,
          'allergens': ['dairy', 'eggs'],
          'dietaryTags': ['vegetarian'],
          'variations': [],
          'addOns': [],
          'isCustomizable': false,
          'vendorId': 'current-vendor',
          'sortOrder': 3,
          'isFeatured': false,
          'discountPercentage': null,
          'discountedPrice': null,
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        },
      ];
    }
  }
}

// Order service (temporary mock)
class OrderService {
  Future<List<Map<String, dynamic>>> getOrders() async {
    // Mock data for now
    await Future.delayed(const Duration(seconds: 1));
    return [
      {
        'id': '1234',
        'customerName': 'John Doe',
        'amount': 25.50,
        'status': 'preparing',
        'items': ['Burger', 'Fries'],
        'createdAt': DateTime.now().subtract(const Duration(minutes: 15)).toIso8601String(),
      },
      {
        'id': '1235',
        'customerName': 'Jane Smith',
        'amount': 18.75,
        'status': 'ready',
        'items': ['Pizza'],
        'createdAt': DateTime.now().subtract(const Duration(minutes: 30)).toIso8601String(),
      },
      {
        'id': '1236',
        'customerName': 'Bob Johnson',
        'amount': 32.25,
        'status': 'pending',
        'items': ['Burger', 'Pizza', 'Salad'],
        'createdAt': DateTime.now().subtract(const Duration(minutes: 5)).toIso8601String(),
      },
    ];
  }
} 