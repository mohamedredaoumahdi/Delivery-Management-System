import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/pages/login_page.dart';
import '../features/dashboard/presentation/pages/dashboard_page.dart';
import '../features/users/presentation/pages/users_page.dart';
import '../features/users/presentation/pages/user_details_page.dart';
import '../features/shops/presentation/pages/shops_page.dart';
import '../features/shops/presentation/pages/shop_details_page.dart';
import '../features/shops/presentation/pages/vendor_performance_page.dart';
import '../features/orders/presentation/pages/orders_page.dart';
import '../features/orders/presentation/pages/order_details_page.dart';
import '../features/analytics/presentation/pages/analytics_page.dart';
import '../features/analytics/presentation/pages/orders_analytics_page.dart';
import '../features/analytics/presentation/pages/revenue_analytics_page.dart';
import '../features/analytics/presentation/pages/vendor_analytics_page.dart';
import '../features/analytics/presentation/pages/delivery_analytics_page.dart';
import '../features/analytics/presentation/pages/customer_analytics_page.dart';

class AppRouter {
  // Web-style page transition (instant - no animations)
  static Page<T> _buildPage<T extends Object?>(
    Widget child,
    GoRouterState state,
  ) {
    // Use NoTransitionPage for instant web-like navigation (no slide animations)
    return NoTransitionPage<T>(
      key: state.pageKey,
      child: child,
    );
  }

  static final GoRouter router = GoRouter(
    initialLocation: '/login',
    // Disable default page transitions for web-style navigation
    restorationScopeId: 'app',
    routes: [
      // Authentication
      GoRoute(
        path: '/login',
        name: 'login',
        pageBuilder: (context, state) => _buildPage(
          const LoginPage(),
          state,
        ),
      ),
      
      // Main App Routes (protected)
      GoRoute(
        path: '/dashboard',
        name: 'dashboard',
        pageBuilder: (context, state) => _buildPage(
          const DashboardPage(),
          state,
        ),
      ),
      
      // Users Management
      GoRoute(
        path: '/users',
        name: 'users',
        pageBuilder: (context, state) => _buildPage(
          const UsersPage(),
          state,
        ),
      ),
      GoRoute(
        path: '/users/:id',
        name: 'user-details',
        pageBuilder: (context, state) {
          final userId = state.pathParameters['id']!;
          return _buildPage(
            UserDetailsPage(userId: userId),
            state,
          );
        },
      ),
      
      // Shops Management
      GoRoute(
        path: '/shops',
        name: 'shops',
        pageBuilder: (context, state) => _buildPage(
          const ShopsPage(),
          state,
        ),
      ),
      GoRoute(
        path: '/shops/:id',
        name: 'shop-details',
        pageBuilder: (context, state) {
          final shopId = state.pathParameters['id']!;
          return _buildPage(
            ShopDetailsPage(shopId: shopId),
            state,
          );
        },
      ),
      GoRoute(
        path: '/shops/:id/performance',
        name: 'vendor-performance',
        pageBuilder: (context, state) {
          final shopId = state.pathParameters['id']!;
          return _buildPage(
            VendorPerformancePage(shopId: shopId),
            state,
          );
        },
      ),
      
      // Orders Management
      GoRoute(
        path: '/orders',
        name: 'orders',
        pageBuilder: (context, state) => _buildPage(
          const OrdersPage(),
          state,
        ),
      ),
      GoRoute(
        path: '/orders/:id',
        name: 'order-details',
        pageBuilder: (context, state) {
          final orderId = state.pathParameters['id']!;
          return _buildPage(
            OrderDetailsPage(orderId: orderId),
            state,
          );
        },
      ),
      
      // Analytics
      GoRoute(
        path: '/analytics',
        name: 'analytics',
        pageBuilder: (context, state) => _buildPage(
          const AnalyticsPage(),
          state,
        ),
      ),
      GoRoute(
        path: '/analytics/orders',
        name: 'orders-analytics',
        pageBuilder: (context, state) => _buildPage(
          const OrdersAnalyticsPage(),
          state,
        ),
      ),
      GoRoute(
        path: '/analytics/revenue',
        name: 'revenue-analytics',
        pageBuilder: (context, state) => _buildPage(
          const RevenueAnalyticsPage(),
          state,
        ),
      ),
      GoRoute(
        path: '/analytics/vendors',
        name: 'vendor-analytics',
        pageBuilder: (context, state) => _buildPage(
          const VendorAnalyticsPage(),
          state,
        ),
      ),
      GoRoute(
        path: '/analytics/delivery',
        name: 'delivery-analytics',
        pageBuilder: (context, state) => _buildPage(
          const DeliveryAnalyticsPage(),
          state,
        ),
      ),
      GoRoute(
        path: '/analytics/customers',
        name: 'customer-analytics',
        pageBuilder: (context, state) => _buildPage(
          const CustomerAnalyticsPage(),
          state,
        ),
      ),
    ],
    
    // Note: Authentication redirect can be implemented here when auth system is added
    // Example implementation:
    // redirect: (context, state) {
    //   final authBloc = context.read<AuthBloc>();
    //   final isLoggedIn = authBloc.state is Authenticated;
    //   final isLoginPage = state.matchedLocation == '/login';
    //   
    //   if (!isLoggedIn && !isLoginPage) {
    //     return '/login';
    //   }
    //   
    //   if (isLoggedIn && isLoginPage) {
    //     return '/dashboard';
    //   }
    //   
    //   return null;
    // },
    
    // Error handling
    errorBuilder: (context, state) => Scaffold(
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
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'The page you are looking for does not exist.',
              style: Theme.of(context).textTheme.bodyMedium,
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

