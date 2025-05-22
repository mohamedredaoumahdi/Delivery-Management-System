import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:ui_kit/ui_kit.dart';

import 'config/routes.dart';
import 'di/injection.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';

// Global GetIt instance
final getIt = GetIt.instance;

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize dependency injection
  await initializeDependencies();
  
  // Run the app
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (context) => getIt<AuthBloc>()..add(AuthCheckStatusEvent()),
        ),
        BlocProvider<HomeBloc>(
          create: (context) => getIt<HomeBloc>()..add(const HomeLoadEvent()),
        ),
        BlocProvider<ShopListBloc>(
          create: (context) => getIt<ShopListBloc>(),
        ),
        BlocProvider<CartBloc>(
          create: (context) => getIt<CartBloc>()..add(const CartLoadEvent()),
        ),
      ],
      child: MaterialApp.router(
        title: 'Delivery App',
        theme: DeliverySystemTheme.defaultTheme().themeData,
        darkTheme: DeliverySystemTheme.defaultTheme().darkThemeData,
        themeMode: ThemeMode.system,
        routerConfig: appRouter,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}