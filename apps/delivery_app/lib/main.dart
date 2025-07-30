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
import 'features/profile/presentation/bloc/profile_bloc.dart';

void main() async {
  print('🚀 DeliveryApp: Starting application initialization');
  
  WidgetsFlutterBinding.ensureInitialized();
  print('✅ DeliveryApp: Flutter binding initialized');
  
  // Initialize Hive for local storage
  await Hive.initFlutter();
  print('✅ DeliveryApp: Hive storage initialized');
  
  // Configure system UI
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  print('✅ DeliveryApp: System UI configured');
  
  // Initialize dependency injection
  print('🔧 DeliveryApp: Configuring dependencies...');
  await configureDependencies();
  print('✅ DeliveryApp: Dependencies configured successfully');
  
  print('🎯 DeliveryApp: Starting app...');
  runApp(const DeliveryApp());
}

class DeliveryApp extends StatelessWidget {
  const DeliveryApp({super.key});

  @override
  Widget build(BuildContext context) {
    print('🎨 DeliveryApp: Building app widget');
    
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (context) {
            print('🔧 DeliveryApp: Creating AuthBloc and adding AuthCheckStatusEvent');
            return getIt<AuthBloc>()..add(const AuthCheckStatusEvent());
          },
        ),
        BlocProvider<DeliveryBloc>(
          create: (context) {
            print('🔧 DeliveryApp: Creating DeliveryBloc');
            return getIt<DeliveryBloc>();
          },
        ),
        BlocProvider<LocationBloc>(
          create: (context) {
            print('🔧 DeliveryApp: Creating LocationBloc');
            return getIt<LocationBloc>();
          },
        ),
        BlocProvider<EarningsBloc>(
          create: (context) => getIt<EarningsBloc>(),
        ),
        BlocProvider<ProfileBloc>(
          create: (context) {
            print('🔧 DeliveryApp: Creating ProfileBloc');
            return getIt<ProfileBloc>();
          },
        ),
      ],
      child: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          print('🎧 DeliveryApp: Auth state changed to ${state.runtimeType}');
          if (state is AuthUnauthenticated) {
            print('🔓 DeliveryApp: User is unauthenticated, navigating to login');
            AppRouter.router.go('/login');
          }
        },
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
      ),
    );
  }
} 