import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/di/injection.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/delivery/presentation/bloc/delivery_bloc.dart';
import 'features/location/presentation/bloc/location_bloc.dart';
import 'features/earnings/presentation/bloc/earnings_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive for local storage
  await Hive.initFlutter();
  
  // Configure system UI
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  
  // Initialize dependency injection
  await configureDependencies();
  
  runApp(const DeliveryApp());
}

class DeliveryApp extends StatelessWidget {
  const DeliveryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (context) => getIt<AuthBloc>()..add(const AuthCheckStatusEvent()),
        ),
        BlocProvider<DeliveryBloc>(
          create: (context) => getIt<DeliveryBloc>(),
        ),
        BlocProvider<LocationBloc>(
          create: (context) => getIt<LocationBloc>(),
        ),
        BlocProvider<EarningsBloc>(
          create: (context) => getIt<EarningsBloc>(),
        ),
      ],
      child: MaterialApp.router(
        title: 'Delivery Driver',
        theme: DeliveryAppTheme.lightTheme,
        darkTheme: DeliveryAppTheme.darkTheme,
        themeMode: ThemeMode.system,
        routerConfig: AppRouter.router,
        debugShowCheckedModeBanner: false,
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(1.0),
            ),
            child: child!,
          );
        },
      ),
    );
  }
} 