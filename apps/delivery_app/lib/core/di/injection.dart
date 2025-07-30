import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import '../../features/delivery/data/delivery_service.dart';
import '../../features/auth/data/auth_service.dart';
import '../../features/profile/data/profile_service.dart';
import '../../features/delivery/presentation/bloc/delivery_bloc.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/profile/presentation/bloc/profile_bloc.dart';
import '../../features/location/presentation/bloc/location_bloc.dart';
import '../../features/dashboard/data/dashboard_service.dart';
import '../../features/dashboard/presentation/bloc/dashboard_bloc.dart';
import '../../features/earnings/data/earnings_service.dart';
import '../../features/earnings/presentation/bloc/earnings_bloc.dart';
import '../network/auth_interceptor.dart';

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
  
  // Register AuthInterceptor first (it needs SharedPreferences)
  getIt.registerLazySingleton<AuthInterceptor>(() => AuthInterceptor(getIt<SharedPreferences>()));
  
  // Configure Dio
  getIt.registerLazySingleton<Dio>(() {
    final dio = Dio();
    dio.options.baseUrl = 'http://localhost:8000/api';
    dio.options.connectTimeout = const Duration(minutes: 2); // Increased timeout
    dio.options.receiveTimeout = const Duration(minutes: 2); // Increased timeout
    dio.options.sendTimeout = const Duration(minutes: 2); // Increased timeout
    
    // Add logging interceptor for debugging
    dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      requestHeader: true,
      responseHeader: false,
      error: true,
    ));
    
    // Add auth interceptor
    dio.interceptors.add(getIt<AuthInterceptor>());
    
    return dio;
  });
  
  // Register services manually since they depend on manually registered dependencies
  getIt.registerLazySingleton<AuthService>(() => AuthService(getIt<Dio>(), getIt<SharedPreferences>()));
  getIt.registerLazySingleton<DeliveryService>(() => DeliveryService(getIt<Dio>()));
  getIt.registerLazySingleton<ProfileService>(() => ProfileService(getIt<Dio>(), getIt<SharedPreferences>()));
  
  // Register DashboardService
  getIt.registerLazySingleton(() => DashboardService(getIt<Dio>(), getIt<SharedPreferences>()));

  // Register EarningsService
  getIt.registerLazySingleton(() => EarningsService(getIt<Dio>()));
  
  // Register blocs manually since they depend on manually registered services
  getIt.registerFactory<DeliveryBloc>(() => DeliveryBloc(getIt<DeliveryService>()));
  getIt.registerFactory<AuthBloc>(() => AuthBloc(getIt<AuthService>()));
  getIt.registerFactory<ProfileBloc>(() => ProfileBloc(getIt<ProfileService>()));
  getIt.registerFactory<LocationBloc>(() => LocationBloc());
  getIt.registerFactory(() => DashboardBloc(getIt<DashboardService>(), getIt<DeliveryService>()));
  getIt.registerFactory(() => EarningsBloc(getIt<EarningsService>()));
} 