import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/bloc/auth_bloc.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/pages/signup_page.dart';
import '../features/auth/presentation/pages/forgot_password_page.dart';
import '../features/home/presentation/pages/home_page.dart';
import '../features/shop/presentation/pages/shop_list_page.dart';
import '../features/shop/presentation/pages/shop_details_page.dart';
import '../features/shop/presentation/pages/product_details_page.dart';
import '../features/shop/presentation/bloc/product_details_bloc.dart';
import '../features/cart/presentation/pages/cart_page.dart';
import '../features/cart/domain/cart_repository.dart';
import '../features/order/presentation/pages/checkout_page.dart';
import '../features/order/presentation/pages/order_list_page.dart';
import '../features/order/presentation/pages/order_details_page.dart';
import '../features/order/presentation/pages/order_tracking_page.dart';
import '../features/profile/presentation/pages/profile_page.dart';
import '../features/profile/presentation/pages/edit_profile_page.dart';
import '../features/profile/presentation/pages/change_password_page.dart';
import '../features/search/presentation/pages/search_page.dart';
import '../di/injection.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

// Create the router configuration
final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  debugLogDiagnostics: true,
  redirect: (BuildContext context, GoRouterState state) {
    final authState = context.read<AuthBloc>().state;
    final isLoggedIn = authState is AuthAuthenticated;
    
    // If the user is not logged in, redirect to login page
    // except for login, signup, and forgot password pages
    final currentLocation = state.uri.toString();
    final isGoingToLogin = currentLocation == '/login';
    final isGoingToSignup = currentLocation == '/signup';
    final isGoingToForgotPassword = currentLocation == '/forgot-password';
    
    if (!isLoggedIn && 
        !isGoingToLogin && 
        !isGoingToSignup && 
        !isGoingToForgotPassword) {
      return '/login';
    }
    
    // If the user is logged in and going to login page, redirect to home page
    if (isLoggedIn && 
        (isGoingToLogin || isGoingToSignup || isGoingToForgotPassword)) {
      return '/';
    }
    
    // No redirect
    return null;
  },
  routes: [
    // Auth routes
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: '/signup',
      builder: (context, state) => const SignupPage(),
    ),
    GoRoute(
      path: '/forgot-password',
      builder: (context, state) => const ForgotPasswordPage(),
    ),
    
    // Search route (standalone)
    GoRoute(
      path: '/search',
      builder: (context, state) {
        final query = state.uri.queryParameters['q'];
        return SearchPage(initialQuery: query);
      },
    ),
    
    // Main app shell with bottom navigation
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) {
        return ScaffoldWithBottomNavBar(
          location: state.uri.toString(),
          child: child,
        );
      },
      routes: [
        // Home route
        GoRoute(
          path: '/',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: HomePage(),
          ),
          routes: [
            // Shop routes
            GoRoute(
              path: 'shops',
              builder: (context, state) => const ShopListPage(),
            ),
            GoRoute(
              path: 'shops/:id',
              builder: (context, state) {
                final shopId = state.pathParameters['id']!;
                return ShopDetailsPage(shopId: shopId);
              },
              routes: [
                GoRoute(
                  path: 'products/:productId',
                  builder: (context, state) {
                    final shopId = state.pathParameters['id']!;
                    final productId = state.pathParameters['productId']!;
                    return BlocProvider<ProductDetailsBloc>(
                      create: (context) => getIt<ProductDetailsBloc>(),
                      child: ProductDetailsPage(
                        shopId: shopId,
                        productId: productId,
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
        
        // Cart route
        GoRoute(
          path: '/cart',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: CartPage(),
          ),
          routes: [
            // Checkout route nested under cart
        GoRoute(
              path: 'checkout',
          builder: (context, state) {
            final summary = state.extra as CartSummary?;
            return CheckoutPage(summary: summary);
          },
            ),
          ],
        ),
        
        // Orders route
        GoRoute(
          path: '/orders',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: OrderListPage(),
          ),
          routes: [
            GoRoute(
              path: ':id',
              builder: (context, state) {
                final orderId = state.pathParameters['id']!;
                return OrderDetailsPage(orderId: orderId);
              },
            ),
            GoRoute(
              path: ':id/tracking',
              builder: (context, state) {
                final orderId = state.pathParameters['id']!;
                return OrderTrackingPage(orderId: orderId);
              },
            ),
          ],
        ),
        
        // Profile route
        GoRoute(
          path: '/profile',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: ProfilePage(),
          ),
          routes: [
            GoRoute(
              path: 'edit',
              builder: (context, state) => const EditProfilePage(),
            ),
            GoRoute(
              path: 'change-password',
              builder: (context, state) => const ChangePasswordPage(),
            ),
          ],
        ),
      ],
    ),
  ],
);

// Scaffold with bottom navigation bar
class ScaffoldWithBottomNavBar extends StatelessWidget {
  final String location;
  final Widget child;

  const ScaffoldWithBottomNavBar({
    super.key,
    required this.location,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _calculateSelectedIndex(location),
        onDestinationSelected: (int index) {
          _onItemTapped(index, context);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.shopping_cart_outlined),
            selectedIcon: Icon(Icons.shopping_cart),
            label: 'Cart',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_outlined),
            selectedIcon: Icon(Icons.receipt),
            label: 'Orders',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  int _calculateSelectedIndex(String location) {
    if (location.startsWith('/')) {
      final String path = location == '/' ? '/' : '/${location.split('/')[1]}';
      switch (path) {
        case '/':
          return 0;
        case '/cart':
          return 1;
        case '/orders':
          return 2;
        case '/profile':
          return 3;
        default:
          return 0;
      }
    }
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/');
        break;
      case 1:
        context.go('/cart');
        break;
      case 2:
        context.go('/orders');
        break;
      case 3:
        context.go('/profile');
        break;
    }
  }
}