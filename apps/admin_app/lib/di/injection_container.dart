import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../config/app_config.dart';
import '../features/auth/presentation/bloc/auth_bloc.dart';
import '../features/auth/data/admin_auth_service.dart';
import '../features/users/data/user_service.dart';
import '../features/users/presentation/bloc/user_bloc.dart';
import '../features/shops/data/shop_service.dart';
import '../features/shops/presentation/bloc/shop_bloc.dart';
import '../features/dashboard/data/dashboard_service.dart';
import '../features/dashboard/presentation/bloc/dashboard_bloc.dart';
import '../features/orders/data/order_service.dart';
import '../features/orders/presentation/bloc/order_bloc.dart';
import '../features/analytics/data/analytics_service.dart';

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
      baseUrl: AppConfig.apiBaseUrl,
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
        final token = sl<SharedPreferences>().getString('access_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        // Handle 401 unauthorized with token refresh
        if (error.response?.statusCode == 401) {
          // Skip token refresh for auth endpoints to avoid infinite loops
          if (error.requestOptions.path.contains('/auth/')) {
            handler.next(error);
            return;
          }
          
          final refreshToken = sl<SharedPreferences>().getString('refresh_token');
          
          if (refreshToken != null) {
            try {
              // Create a temporary Dio instance for refresh (without auth interceptor to avoid loops)
              final refreshDio = Dio();
              refreshDio.options = BaseOptions(
                baseUrl: AppConfig.apiBaseUrl,
                connectTimeout: const Duration(seconds: 30),
                receiveTimeout: const Duration(seconds: 30),
                headers: {
                  'Content-Type': 'application/json',
                  'Accept': 'application/json',
                },
              );
              
              // Attempt to refresh token
              final refreshResponse = await refreshDio.post(
                '/auth/refresh',
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
              // If refresh fails, clear tokens and redirect to login
              await sl<SharedPreferences>().remove('access_token');
              await sl<SharedPreferences>().remove('refresh_token');
            }
          } else {
            // No refresh token available, clear access token
            await sl<SharedPreferences>().remove('access_token');
          }
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
  
  // Services
  sl.registerLazySingleton<AdminAuthService>(
    () => AdminAuthService(sl<SharedPreferences>(), sl<Dio>()),
  );
  
  sl.registerLazySingleton<UserService>(
    () => UserService(sl<Dio>()),
  );
  
  sl.registerLazySingleton<ShopService>(
    () => ShopService(sl<Dio>()),
  );
  
  sl.registerLazySingleton<DashboardService>(
    () => DashboardService(sl<Dio>()),
  );
  
  sl.registerLazySingleton<OrderService>(
    () => OrderService(sl<Dio>()),
  );
  
  sl.registerLazySingleton<AnalyticsService>(
    () => AnalyticsService(sl<Dio>()),
  );
  
  // Blocs
  sl.registerFactory(() => AuthBloc(
    authService: sl<AdminAuthService>(),
  ));
  
  sl.registerFactory(() => UserBloc(
    userService: sl<UserService>(),
  ));
  
  sl.registerFactory(() => ShopBloc(
    shopService: sl<ShopService>(),
  ));
  
  sl.registerFactory(() => DashboardBloc(
    dashboardService: sl<DashboardService>(),
  ));
  
  sl.registerFactory(() => OrderBloc(
    orderService: sl<OrderService>(),
  ));
}

