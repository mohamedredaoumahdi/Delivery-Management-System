import 'package:core/core.dart' as core;
import 'package:core/core.dart';
import 'package:data/data.dart';
import 'package:dio/dio.dart';
import 'package:domain/domain.dart';
import 'package:get_it/get_it.dart';
import 'package:data/src/api/api_client.dart' as data_api;

// Corrected imports for Order related repositories
import 'package:data/src/repositories/order_repository_impl.dart';

import '../features/auth/presentation/bloc/auth_bloc.dart';
import '../features/shop/presentation/bloc/shop_list_bloc.dart';
import '../features/cart/domain/cart_repository.dart';
import '../features/cart/data/cart_repository_impl.dart';
import '../features/cart/presentation/bloc/cart_bloc.dart';
import '../features/home/presentation/bloc/home_bloc.dart';
import '../features/shop/data/shop_repository_impl.dart';
import '../features/shop/presentation/bloc/shop_details_bloc.dart';
import '../features/shop/presentation/bloc/product_list_bloc.dart';
import '../features/order/presentation/bloc/order_bloc.dart';

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
  
  // API Client
  final dio = Dio();
  dio.options.headers['Content-Type'] = 'application/json';
  getIt.registerSingleton<Dio>(dio);
  
  getIt.registerSingleton<core.ApiClient>(
    core.ApiClient(
      baseUrl: 'http://localhost:3000/api', // Node.js server
      dio: getIt<Dio>(),
    ),
  );
  getIt.registerSingleton<data_api.ApiClient>(
    data_api.ApiClient(
      baseUrl: 'http://localhost:3000/api', // Node.js server
      dio: getIt<Dio>(),
    ),
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

  // Register OrderBloc
  getIt.registerFactory<OrderBloc>(
    () => OrderBloc(
      orderRepository: getIt<OrderRepository>(),
    ),
  );
}