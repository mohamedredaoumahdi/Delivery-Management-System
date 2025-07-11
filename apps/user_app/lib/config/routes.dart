import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:domain/domain.dart';

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
import '../features/profile/presentation/pages/notification_settings_page.dart';
import '../features/profile/presentation/pages/language_settings_page.dart';
import '../features/profile/presentation/pages/theme_settings_page.dart';
import '../features/address/presentation/pages/addresses_page.dart';
import '../features/address/presentation/pages/add_edit_address_page.dart';
import '../features/address/presentation/bloc/address_bloc.dart';
import '../features/payment_method/presentation/pages/payment_methods_page.dart';
import '../features/payment_method/presentation/pages/add_edit_payment_method_page.dart';
import '../features/payment_method/presentation/bloc/payment_method_bloc.dart';
import '../features/search/presentation/pages/search_page.dart';
import '../di/injection.dart';
import '../core/auth/auth_manager.dart';

final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

// Create the router configuration
final appRouter = GoRouter(
  navigatorKey: AuthManager.navigatorKey,
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
              builder: (context, state) {
                final extra = state.extra as Map<String, dynamic>?;
                final categoryFromExtra = extra?['category'] as ShopCategory?;
                final showNearby = extra?['nearby'] as bool? ?? false;
                
                // Also check for category in query parameters
                final categoryFromQuery = state.uri.queryParameters['category'];
                ShopCategory? category = categoryFromExtra;
                
                if (categoryFromQuery != null) {
                  // Convert string to enum
                  category = ShopCategory.values.firstWhere(
                    (e) => e.name == categoryFromQuery,
                    orElse: () => ShopCategory.restaurant,
                  );
                }
                
                return ShopListPage(
                  initialCategory: category,
                  showNearby: showNearby,
                );
              },
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
                return MultiBlocProvider(
                  providers: [
                    BlocProvider<AddressBloc>(
                      create: (context) => getIt<AddressBloc>(),
                    ),
                    BlocProvider<PaymentMethodBloc>(
                      create: (context) => getIt<PaymentMethodBloc>(),
                    ),
                  ],
                  child: CheckoutPage(summary: summary),
                );
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
            GoRoute(
              path: 'notifications',
              builder: (context, state) => const NotificationSettingsPage(),
            ),
            GoRoute(
              path: 'language',
              builder: (context, state) => const LanguageSettingsPage(),
            ),
            GoRoute(
              path: 'theme',
              builder: (context, state) => const ThemeSettingsPage(),
            ),
            GoRoute(
              path: 'addresses',
              builder: (context, state) => BlocProvider<AddressBloc>(
                create: (context) => getIt<AddressBloc>(),
                child: const AddressesPage(),
              ),
              routes: [
                GoRoute(
                  path: 'add',
                  builder: (context, state) => BlocProvider<AddressBloc>(
                    create: (context) => getIt<AddressBloc>(),
                    child: const AddEditAddressPage(),
                  ),
                ),
                GoRoute(
                  path: 'edit/:addressId',
                  builder: (context, state) {
                    final addressId = state.pathParameters['addressId']!;
                    // TODO: We might want to pass the address object if we have it
                    return BlocProvider<AddressBloc>(
                      create: (context) => getIt<AddressBloc>(),
                      child: AddEditAddressPage(addressId: addressId),
                    );
                  },
                ),
              ],
            ),
            GoRoute(
              path: 'payment-methods',
              builder: (context, state) => BlocProvider<PaymentMethodBloc>(
                create: (context) => getIt<PaymentMethodBloc>(),
                child: const PaymentMethodsPage(),
              ),
              routes: [
                GoRoute(
                  path: 'add',
                  builder: (context, state) => BlocProvider<PaymentMethodBloc>(
                    create: (context) => getIt<PaymentMethodBloc>(),
                    child: const AddEditPaymentMethodPage(),
                  ),
                ),
                GoRoute(
                  path: 'edit/:paymentMethodId',
                  builder: (context, state) {
                    final paymentMethodId = state.pathParameters['paymentMethodId']!;
                    return BlocProvider<PaymentMethodBloc>(
                      create: (context) => getIt<PaymentMethodBloc>(),
                      child: AddEditPaymentMethodPage(paymentMethodId: paymentMethodId),
                    );
                  },
                ),
              ],
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