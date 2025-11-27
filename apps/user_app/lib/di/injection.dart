import 'package:core/core.dart';
import 'package:data/data.dart' hide ApiClient;
import 'package:dio/dio.dart';
import 'package:domain/domain.dart';
import 'package:get_it/get_it.dart';
import 'package:data/src/api/api_client.dart' as data_api;

// Corrected imports for Order related repositories
import 'package:data/src/repositories/order_repository_impl.dart';

import '../features/auth/presentation/bloc/auth_bloc.dart';
import '../features/address/presentation/bloc/address_bloc.dart';
import '../features/payment_method/presentation/bloc/payment_method_bloc.dart';
import '../features/shop/presentation/bloc/shop_list_bloc.dart';
import '../features/cart/domain/cart_repository.dart';
import '../features/cart/data/cart_repository_impl.dart';
import '../features/cart/presentation/bloc/cart_bloc.dart';
import '../features/home/presentation/bloc/home_bloc.dart';
import '../features/shop/data/shop_repository_impl.dart';
import '../features/shop/presentation/bloc/shop_details_bloc.dart';
import '../features/shop/presentation/bloc/product_details_bloc.dart';
import '../features/shop/presentation/bloc/product_list_bloc.dart';
import '../features/order/presentation/bloc/order_bloc.dart';
import '../features/location/presentation/bloc/location_bloc.dart';
import '../core/location/location_service.dart';
import '../core/realtime/socket_service.dart';
import '../core/notifications/push_notification_service.dart';
import '../features/order/presentation/bloc/realtime_order_bloc.dart';
import '../core/auth/auth_manager.dart';

final getIt = GetIt.instance;

Future<void> initializeDependencies() async {
  // Core services
  getIt.registerSingleton<LoggerService>(LoggerService());
  
  final storageService = StorageService();
  await storageService.initialize();
  getIt.registerSingleton<StorageService>(storageService);
  
  final connectivityService = ConnectivityService();
  await connectivityService.initialize();
  getIt.registerSingleton<ConnectivityService>(connectivityService);
  
  // Create authentication manager
  final authManager = AuthManager();
  getIt.registerSingleton<AuthManager>(authManager);
  
  // Location service
  getIt.registerSingleton<LocationService>(
    LocationService(getIt<LoggerService>()),
  );
  
  // Socket service
  getIt.registerSingleton<SocketService>(
    SocketService(
      logger: getIt<LoggerService>(),
      baseUrl: 'http://localhost:3000', // TODO: Make this configurable
      authToken: null, // Will be updated when user logs in
    ),
  );
  
  // Push notification service
  getIt.registerSingleton<PushNotificationService>(
    PushNotificationService(getIt<LoggerService>()),
  );
  
  // API Client with proper configuration
  final dio = Dio();
  
  // Configure Dio with base URL and interceptors
  dio.options.baseUrl = Environment.baseUrl;
  dio.options.connectTimeout = const Duration(seconds: 30);
  dio.options.receiveTimeout = const Duration(seconds: 30);
  dio.options.sendTimeout = const Duration(seconds: 30);
  
  // Add logging interceptor for debugging
  if (Environment.isDevelopment) {
    dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      requestHeader: true,
      responseHeader: false,
      error: true,
    ));
  }
  
  // Add auth interceptor
  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) async {
      // Add auth token if available
      final token = getIt<StorageService>().getString('auth_token');
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      handler.next(options);
    },
    onError: (error, handler) async {
      // Handle 401 errors by clearing token and triggering logout
      if (error.response?.statusCode == 401) {
        getIt<LoggerService>().w('Auth token expired or invalid, clearing tokens');
        await getIt<StorageService>().remove('auth_token');
        await getIt<StorageService>().remove('refresh_token');
        
        // Trigger logout through auth manager
        getIt<AuthManager>().handleAuthError();
      }
      handler.next(error);
    },
  ));
  
  getIt.registerSingleton<Dio>(dio);
  
  getIt.registerSingleton<data_api.ApiClient>(
    data_api.ApiClient(getIt<Dio>()),
  );
  
  // Data Sources
  getIt.registerSingleton<AuthLocalDataSource>(
    AuthLocalDataSourceImpl(
      storageService: getIt<StorageService>(),
      logger: getIt<LoggerService>(),
    ),
  );
  
  getIt.registerSingleton<AuthRemoteDataSource>(
    AuthRemoteDataSourceImpl(
      apiClient: getIt<data_api.ApiClient>(),
      logger: getIt<LoggerService>(),
    ),
  );
  
  // Repositories
  getIt.registerSingleton<AuthRepository>(
    AuthRepositoryImpl(
      remoteDataSource: getIt<AuthRemoteDataSource>(),
      localDataSource: getIt<AuthLocalDataSource>(),
      logger: getIt<LoggerService>(),
    ),
  );
  
  // Shop Repository
  getIt.registerSingleton<ShopRepository>(
    ShopRepositoryImpl(
      apiClient: getIt<data_api.ApiClient>(),
      logger: getIt<LoggerService>(),
    ),
  );
  
  // Order Repository
  getIt.registerSingleton<OrderRepository>(
    OrderRepositoryImpl(
      apiClient: getIt<data_api.ApiClient>(),
      logger: getIt<LoggerService>(),
    ),
  );
  
  // Address Repository
  getIt.registerSingleton<AddressRepository>(
    AddressRepositoryImpl(
      apiClient: getIt<data_api.ApiClient>(),
      logger: getIt<LoggerService>(),
    ),
  );
  
  // Payment Method Repository
  getIt.registerSingleton<PaymentMethodRepository>(
    PaymentMethodRepositoryImpl(
      apiClient: getIt<data_api.ApiClient>(),
      logger: getIt<LoggerService>(),
    ),
  );
  
  // Local repositories
  getIt.registerSingleton<CartRepository>(
    CartRepositoryImpl(
      storageService: getIt<StorageService>(),
      logger: getIt<LoggerService>(),
    ),
  );
  
  // BLoCs
  getIt.registerFactory<AuthBloc>(
    () => AuthBloc(
      authRepository: getIt<AuthRepository>(),
    ),
  );
  
  getIt.registerFactory<ShopListBloc>(
    () => ShopListBloc(
      shopRepository: getIt<ShopRepository>(),
    ),
  );
  
  getIt.registerFactory<CartBloc>(
    () => CartBloc(
      cartRepository: getIt<CartRepository>(),
    ),
  );
  
  getIt.registerFactory<HomeBloc>(
    () => HomeBloc(),
  );

  // Register ShopDetailsBloc
  getIt.registerFactory<ShopDetailsBloc>(
    () => ShopDetailsBloc(getIt<ShopRepository>()),
  );

  // Register ProductListBloc
  getIt.registerFactory<ProductListBloc>(
    () => ProductListBloc(getIt<ShopRepository>()),
  );

  // Register ProductDetailsBloc
  getIt.registerFactory<ProductDetailsBloc>(
    () => ProductDetailsBloc(getIt<ShopRepository>()),
  );

  // Register OrderBloc
  getIt.registerFactory<OrderBloc>(
    () => OrderBloc(
      orderRepository: getIt<OrderRepository>(),
    ),
  );

  // Register AddressBloc
  getIt.registerFactory<AddressBloc>(
    () => AddressBloc(
      addressRepository: getIt<AddressRepository>(),
    ),
  );

  // Register PaymentMethodBloc
  getIt.registerFactory<PaymentMethodBloc>(
    () => PaymentMethodBloc(
      paymentMethodRepository: getIt<PaymentMethodRepository>(),
    ),
  );
  
  // Register LocationBloc
  getIt.registerFactory<LocationBloc>(
    () => LocationBloc(
      locationService: getIt<LocationService>(),
      logger: getIt<LoggerService>(),
    ),
  );
  
  // Register RealtimeOrderBloc
  getIt.registerFactory<RealtimeOrderBloc>(
    () => RealtimeOrderBloc(
      socketService: getIt<SocketService>(),
      pushNotificationService: getIt<PushNotificationService>(),
      logger: getIt<LoggerService>(),
    ),
  );
}