import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/pages/register_page.dart';
import '../features/dashboard/presentation/pages/dashboard_page.dart';
import '../features/menu/presentation/pages/menu_management_page.dart';
import '../features/menu/presentation/pages/add_menu_item_page.dart';
import '../features/menu/presentation/pages/edit_menu_item_page.dart';
import '../features/orders/presentation/pages/orders_page.dart';
import '../features/orders/presentation/pages/order_details_page.dart';
import '../features/profile/presentation/pages/profile_page.dart';
import '../features/profile/presentation/pages/edit_profile_page.dart';
import '../features/profile/presentation/pages/notifications_settings_page.dart';
import '../features/profile/presentation/pages/payment_settings_page.dart';
import '../features/profile/presentation/pages/add_payment_method_page.dart';
import '../features/profile/presentation/pages/security_settings_page.dart';
import '../features/profile/presentation/pages/help_center_page.dart';
import '../features/profile/presentation/pages/contact_support_page.dart';
import '../features/analytics/presentation/pages/analytics_page.dart';
import '../common/presentation/pages/main_wrapper_page.dart';
import '../common/presentation/pages/splash_page.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/splash',
    routes: [
      // Splash Screen
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashPage(),
      ),
      
      // Authentication Routes
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterPage(),
      ),
      
      // Main App Routes (with bottom navigation)
      ShellRoute(
        builder: (context, state, child) => MainWrapperPage(child: child),
        routes: [
          // Dashboard
          GoRoute(
            path: '/dashboard',
            name: 'dashboard',
            builder: (context, state) => DashboardPage(
              navigateToTab: (index) {
                switch (index) {
                  case 1:
                    context.go('/menu');
                    break;
                  case 2:
                    context.go('/orders');
                    break;
                  case 3:
                    context.go('/analytics');
                    break;
                }
              },
            ),
          ),
          
          // Orders
          GoRoute(
            path: '/orders',
            name: 'orders',
            builder: (context, state) => const OrdersPage(),
          ),
          
          // Menu Management
          GoRoute(
            path: '/menu',
            name: 'menu',
            builder: (context, state) => const MenuManagementPage(),
          ),
          
          // Analytics
          GoRoute(
            path: '/analytics',
            name: 'analytics',
            builder: (context, state) => const AnalyticsPage(),
          ),
          
          // Profile
          GoRoute(
            path: '/profile',
            name: 'profile',
            builder: (context, state) => ProfilePage(
              navigateToTab: (index) {
                switch (index) {
                  case 3:
                    context.go('/analytics');
                    break;
                }
              },
            ),
          ),
          
          // Add Menu Item (with bottom navigation)
          GoRoute(
            path: '/add-menu-item',
            name: 'add-menu-item',
            builder: (context, state) => const AddMenuItemPage(),
          ),
          
          // Edit Menu Item (with bottom navigation)
          GoRoute(
            path: '/edit-menu-item/:itemId',
            name: 'edit-menu-item',
            builder: (context, state) {
              final itemId = state.pathParameters['itemId']!;
              return EditMenuItemPage(itemId: itemId);
            },
          ),
        ],
      ),
      
      // Standalone Routes (without bottom navigation)
      GoRoute(
        path: '/order-details/:orderId',
        name: 'order-details',
        builder: (context, state) {
          final orderId = state.pathParameters['orderId']!;
          return OrderDetailsPage(orderId: orderId);
        },
      ),
      
      // Profile Settings Routes
      GoRoute(
        path: '/edit-profile',
        name: 'edit-profile',
        builder: (context, state) {
          final user = state.extra as Map<String, dynamic>;
          return EditProfilePage(user: user);
        },
      ),
      GoRoute(
        path: '/notifications-settings',
        name: 'notifications-settings',
        builder: (context, state) => const NotificationsSettingsPage(),
      ),
      GoRoute(
        path: '/payment-settings',
        name: 'payment-settings',
        builder: (context, state) => const PaymentSettingsPage(),
      ),
      GoRoute(
        path: '/add-payment-method',
        name: 'add-payment-method',
        builder: (context, state) => const AddPaymentMethodPage(),
      ),
      GoRoute(
        path: '/help-center',
        name: 'help-center',
        builder: (context, state) => const HelpCenterPage(),
      ),
      GoRoute(
        path: '/contact-support',
        name: 'contact-support',
        builder: (context, state) => const ContactSupportPage(),
      ),
      GoRoute(
        path: '/security-settings',
        name: 'security-settings',
        builder: (context, state) => const SecuritySettingsPage(),
      ),
    ],
    
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