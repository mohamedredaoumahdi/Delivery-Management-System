import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/di/injection.dart';

import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/dashboard/presentation/bloc/dashboard_bloc.dart';
import '../../features/location/presentation/bloc/location_bloc.dart';
import '../../features/delivery/presentation/bloc/delivery_bloc.dart';
import '../../features/earnings/presentation/bloc/earnings_bloc.dart';
import '../../features/profile/presentation/bloc/profile_bloc.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/registration_page.dart';
import '../../features/main/presentation/pages/main_page.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/delivery/presentation/pages/available_deliveries_page.dart';
import '../../features/delivery/presentation/pages/delivery_details_page.dart';
import '../../features/delivery/presentation/pages/navigation_page.dart';
import '../../features/earnings/presentation/pages/earnings_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/profile/presentation/pages/edit_profile_page.dart';

class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  static final _shellNavigatorKey = GlobalKey<NavigatorState>();

  static GoRouter get router => _router;

  static final GoRouter _router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/dashboard',
    redirect: (context, state) {
      final authState = context.read<AuthBloc>().state;
      final isAuthenticated = authState is AuthAuthenticated;
      
      // If not authenticated and not on auth pages, redirect to login
      if (!isAuthenticated && 
          !state.matchedLocation.startsWith('/login') && 
          !state.matchedLocation.startsWith('/register')) {
        return '/login';
      }
      
      // If authenticated and on auth pages, redirect to dashboard
      if (isAuthenticated && 
          (state.matchedLocation.startsWith('/login') || 
           state.matchedLocation.startsWith('/register'))) {
        return '/dashboard';
      }
      
      return null;
    },
    routes: [
      // Authentication Routes
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegistrationPage(),
      ),
      
      // Main App Shell with Bottom Navigation
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return MultiBlocProvider(
            providers: [
              BlocProvider<DashboardBloc>(
                create: (context) => getIt<DashboardBloc>(),
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
              BlocProvider<ProfileBloc>(
                create: (context) => getIt<ProfileBloc>(),
              ),
            ],
            child: MainPage(child: child),
          );
        },
        routes: [
          // Dashboard
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardPage(),
          ),
          
          // Available Deliveries
          GoRoute(
            path: '/deliveries',
            builder: (context, state) => const AvailableDeliveriesPage(),
          ),
          
          // Earnings
          GoRoute(
            path: '/earnings',
            builder: (context, state) => const EarningsPage(),
          ),
          
          // Profile
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfilePage(),
          ),
        ],
      ),
      
      // Delivery Details (outside main shell)
      GoRoute(
        path: '/delivery/:deliveryId',
        builder: (context, state) {
          final deliveryId = state.pathParameters['deliveryId']!;
          return BlocProvider(
            create: (context) => getIt<DeliveryBloc>(),
            child: DeliveryDetailsPage(deliveryId: deliveryId),
          );
        },
      ),
      
      // Navigation/Tracking (outside main shell)
      GoRoute(
        path: '/navigation/:deliveryId',
        builder: (context, state) {
          final deliveryId = state.pathParameters['deliveryId']!;
          return BlocProvider(
            create: (context) => getIt<DeliveryBloc>(),
            child: NavigationPage(deliveryId: deliveryId),
          );
        },
      ),
      
      // Edit Profile (outside main shell)
      GoRoute(
        path: '/profile/edit',
        builder: (context, state) => const EditProfilePage(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Error')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Page not found',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              state.error?.toString() ?? 'Unknown error',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/dashboard'),
              child: const Text('Go to Dashboard'),
            ),
          ],
        ),
      ),
    ),
  );
} 