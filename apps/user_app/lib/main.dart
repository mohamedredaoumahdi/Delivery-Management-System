import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
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
import 'features/address/presentation/bloc/address_bloc.dart';
import 'features/payment_method/presentation/bloc/payment_method_bloc.dart';
import 'features/settings/presentation/bloc/locale_bloc.dart';
import 'features/location/presentation/bloc/location_bloc.dart';
import 'features/order/presentation/bloc/realtime_order_bloc.dart';
import 'core/auth/auth_manager.dart';
import 'package:user_app/l10n/app_localizations.dart';

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

class UserApp extends StatefulWidget {
  const UserApp({super.key});

  @override
  State<UserApp> createState() => _UserAppState();
}

class _UserAppState extends State<UserApp> {
  late final AuthManager _authManager;
  
  @override
  void initState() {
    super.initState();
    _authManager = getIt<AuthManager>();
    
    // Listen to authentication errors
    _authManager.authErrorStream.listen((_) {
      debugPrint('🔐 UserApp: Authentication error detected globally');
      // The navigation is handled by the AuthManager itself
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // Auth BLoC - handles authentication state
        BlocProvider<AuthBloc>(
          create: (context) => getIt<AuthBloc>()..add(AuthCheckStatusEvent()),
        ),
        
        // Locale BLoC - handles app language
        BlocProvider<LocaleBloc>(
          create: (context) => LocaleBloc()..add(const LocaleLoadRequested()),
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
        
        // Address BLoC - handles user delivery addresses
        BlocProvider<AddressBloc>(
          create: (context) => getIt<AddressBloc>(),
        ),
        
        // Payment Method BLoC - handles user payment methods
        BlocProvider<PaymentMethodBloc>(
          create: (context) => getIt<PaymentMethodBloc>(),
        ),
        
        // Location BLoC - handles user location
        BlocProvider<LocationBloc>(
          create: (context) => getIt<LocationBloc>(),
        ),
        
        // Realtime Order BLoC - handles real-time order updates
        BlocProvider<RealtimeOrderBloc>(
          create: (context) => getIt<RealtimeOrderBloc>(),
        ),
      ],
      child: BlocBuilder<LocaleBloc, LocaleState>(
        builder: (context, localeState) {
          debugPrint('🌍 Building app with locale: ${localeState.locale.languageCode}');
          
          return MaterialApp.router(
        title: 'Delivery System - User App',
        
        // Theme configuration
        theme: UserAppTheme.createTheme(),
        darkTheme: UserAppTheme.createDarkTheme(),
        themeMode: ThemeMode.system,
        
        // Router configuration
        routerConfig: appRouter,
        
        // Disable debug banner in release mode
        debugShowCheckedModeBanner: false,
        
            // Localization configuration
            locale: localeState.locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
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
          );
        },
      ),
    );
  }
}