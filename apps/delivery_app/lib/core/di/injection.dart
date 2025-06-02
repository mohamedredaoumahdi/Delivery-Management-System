import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';

import 'injection.config.dart';

final getIt = GetIt.instance;

@InjectableInit()
Future<void> configureDependencies() async {
  // Register external dependencies
  await _registerExternalDependencies();
  
  // Initialize injectable dependencies
  getIt.init();
}

Future<void> _registerExternalDependencies() async {
  // Shared Preferences
  final sharedPreferences = await SharedPreferences.getInstance();
  getIt.registerLazySingleton<SharedPreferences>(() => sharedPreferences);
  
  // Dio HTTP Client
  final dio = Dio();
  dio.options = BaseOptions(
    baseUrl: 'http://localhost:3000/api', // Replace with actual API URL
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
  );
  
  // Add interceptors
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        // Add auth token if available
        final token = sharedPreferences.getString('auth_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) {
        // Handle token expiration
        if (error.response?.statusCode == 401) {
          // Clear token and redirect to login
          sharedPreferences.remove('auth_token');
        }
        handler.next(error);
      },
    ),
  );
  
  getIt.registerLazySingleton<Dio>(() => dio);
} 