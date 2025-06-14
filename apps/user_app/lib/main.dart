import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import 'config/routes.dart';
import 'config/theme.dart';
import 'di/injection.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/home/presentation/bloc/home_bloc.dart';
import 'features/shop/presentation/bloc/shop_list_bloc.dart';
import 'features/shop/presentation/bloc/shop_details_bloc.dart';
import 'features/cart/presentation/bloc/cart_bloc.dart';
import 'features/shop/presentation/bloc/product_list_bloc.dart';
import 'features/order/presentation/bloc/order_bloc.dart';

// Global GetIt instance
final getIt = GetIt.instance;

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize dependency injection
  await initializeDependencies();
  
  // Run the app
  runApp(const UserApp());
}

class UserApp extends StatelessWidget {
  const UserApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // Auth BLoC - handles authentication state
        BlocProvider<AuthBloc>(
          create: (context) => getIt<AuthBloc>()..add(AuthCheckStatusEvent()),
        ),
        
        // Home BLoC - handles home page data
        BlocProvider<HomeBloc>(
          create: (context) => getIt<HomeBloc>()..add(const HomeLoadEvent()),
        ),
        
        // Shop List BLoC - handles shop listings and search
        BlocProvider<ShopListBloc>(
          create: (context) => getIt<ShopListBloc>(),
        ),
        
        // Shop Details BLoC - handles shop details
        BlocProvider<ShopDetailsBloc>(
          create: (context) => getIt<ShopDetailsBloc>(),
        ),
        
        // Product List BLoC - handles product listings for a shop
        BlocProvider<ProductListBloc>(
          create: (context) => getIt<ProductListBloc>(),
        ),
        
        // Cart BLoC - handles shopping cart
        BlocProvider<CartBloc>(
          create: (context) => getIt<CartBloc>()..add(const CartLoadEvent()),
        ),
        
        // Order BLoC - handles order related logic
        BlocProvider<OrderBloc>(
          create: (context) => getIt<OrderBloc>(),
        ),
      ],
      child: MaterialApp.router(
        title: 'Delivery System - User App',
        
        // Theme configuration
        theme: UserAppTheme.createTheme(),
        darkTheme: UserAppTheme.createDarkTheme(),
        themeMode: ThemeMode.system,
        
        // Router configuration
        routerConfig: appRouter,
        
        // Disable debug banner in release mode
        debugShowCheckedModeBanner: false,
        
        // Localization (can be extended later) -
        supportedLocales: const [
          Locale('en', 'US'), // English
          // Add more locales as needed
        ],
        
        // Builder to handle global error scenarios
        builder: (context, child) {
          // Handle text scaling for accessibility
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(
                MediaQuery.of(context).textScaler.scale(1.0).clamp(0.8, 1.2),
              ),
            ),
            child: child!,
          );
        },
      ),
    );
  }
}