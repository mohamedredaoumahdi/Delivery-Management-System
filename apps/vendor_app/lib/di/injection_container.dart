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
    
    // Add interceptors
    dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      requestHeader: true,
      responseHeader: true,
    ));
    
    return dio;
  });
  
  // Mock services until shared packages are ready
  sl.registerLazySingleton<MockAuthService>(() => MockAuthService());
  sl.registerLazySingleton<MockVendorService>(() => MockVendorService());
  sl.registerLazySingleton<MockMenuService>(() => MockMenuService());
  sl.registerLazySingleton<MockOrderService>(() => MockOrderService());
  
  // Blocs with mock dependencies
  sl.registerFactory(() => AuthBloc(
    authService: sl<MockAuthService>(),
  ));
  
  sl.registerFactory(() => DashboardBloc(
    vendorService: sl<MockVendorService>(),
  ));
  
  sl.registerFactory(() => MenuBloc(
    menuService: sl<MockMenuService>(),
  ));
  
  sl.registerFactory(() => OrdersBloc(
    orderService: sl<MockOrderService>(),
  ));
  
  sl.registerFactory(() => ProfileBloc(
    authService: sl<MockAuthService>(),
  ));
  
  sl.registerFactory(() => AnalyticsBloc(
    vendorService: sl<MockVendorService>(),
  ));
}

// Temporary mock services
class MockAuthService {
  Future<Map<String, dynamic>> login(String email, String password) async {
    await Future.delayed(const Duration(seconds: 1));
    if (email == 'vendor@test.com' && password == 'password') {
      return {
        'success': true,
        'user': {
          'id': '1',
          'name': 'Test Vendor',
          'email': email,
          'businessName': 'Test Restaurant',
        }
      };
    }
    throw Exception('Invalid credentials');
  }
  
  Future<Map<String, dynamic>> register(Map<String, String> data) async {
    await Future.delayed(const Duration(seconds: 2));
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
  
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 500));
  }
  
  Future<Map<String, dynamic>?> getCurrentUser() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return null; // Not authenticated by default
  }
}

class MockVendorService {
  Future<Map<String, dynamic>> getDashboardData() async {
    await Future.delayed(const Duration(seconds: 1));
    return {
      'todayOrders': 24,
      'todayRevenue': 480.50,
      'pendingOrders': 3,
      'rating': 4.8,
    };
  }
}

class MockMenuService {
  Future<List<Map<String, dynamic>>> getMenuItems() async {
    await Future.delayed(const Duration(seconds: 1));
    return [
      {
        'id': '1',
        'name': 'Burger',
        'price': 12.99,
        'category': 'Main Course',
        'available': true,
      },
      {
        'id': '2',
        'name': 'Pizza',
        'price': 15.99,
        'category': 'Main Course',
        'available': true,
      },
    ];
  }
}

class MockOrderService {
  Future<List<Map<String, dynamic>>> getOrders() async {
    await Future.delayed(const Duration(seconds: 1));
    return [
      {
        'id': '1234',
        'customerName': 'John Doe',
        'amount': 25.50,
        'status': 'preparing',
        'items': ['Burger', 'Fries'],
      },
      {
        'id': '1235',
        'customerName': 'Jane Smith',
        'amount': 18.75,
        'status': 'ready',
        'items': ['Pizza'],
      },
    ];
  }
} 