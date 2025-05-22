import 'package:core/core.dart';
import 'package:data/data.dart';
import 'package:dio/dio.dart';
import 'package:domain/domain.dart';
import 'package:get_it/get_it.dart';

import '../features/auth/presentation/bloc/auth_bloc.dart';
import '../features/shop/presentation/bloc/shop_list_bloc.dart';
import '../features/cart/domain/cart_repository.dart';
import '../features/cart/data/cart_repository_impl.dart';
import '../features/cart/presentation/bloc/cart_bloc.dart';
import '../features/home/presentation/bloc/home_bloc.dart';

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
  getIt.registerSingleton<Dio>(Dio());
  getIt.registerSingleton<ApiClient>(
    ApiClient(
      baseUrl: 'https://api.deliverysystem.com/v1', // Replace with your API URL
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
      apiClient: getIt<ApiClient>(),
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
}