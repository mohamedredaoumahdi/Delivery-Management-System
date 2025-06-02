import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import 'config/app_config.dart';
import 'config/router_config.dart';
import 'config/theme_config.dart';
import 'di/injection_container.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'features/menu/presentation/bloc/menu_bloc.dart';
import 'features/orders/presentation/bloc/orders_bloc.dart';
import 'features/profile/presentation/bloc/profile_bloc.dart';
import 'features/analytics/presentation/bloc/analytics_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize dependency injection
  await initializeDependencies();
  
  runApp(const VendorApp());
}

class VendorApp extends StatelessWidget {
  const VendorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (context) => GetIt.instance<AuthBloc>()..add(CheckAuthStatus()),
        ),
        BlocProvider<DashboardBloc>(
          create: (context) => GetIt.instance<DashboardBloc>(),
        ),
        BlocProvider<MenuBloc>(
          create: (context) => GetIt.instance<MenuBloc>(),
        ),
        BlocProvider<OrdersBloc>(
          create: (context) => GetIt.instance<OrdersBloc>(),
        ),
        BlocProvider<ProfileBloc>(
          create: (context) => GetIt.instance<ProfileBloc>(),
        ),
        BlocProvider<AnalyticsBloc>(
          create: (context) => GetIt.instance<AnalyticsBloc>(),
        ),
      ],
      child: MaterialApp.router(
        title: AppConfig.appName,
        debugShowCheckedModeBanner: false,
        theme: ThemeConfig.lightTheme,
        darkTheme: ThemeConfig.darkTheme,
        themeMode: ThemeMode.system,
        routerConfig: AppRouter.router,
      ),
    );
  }
} 