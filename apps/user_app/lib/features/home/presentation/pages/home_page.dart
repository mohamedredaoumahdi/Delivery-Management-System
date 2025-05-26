import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:domain/domain.dart';
import 'package:user_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:user_app/features/shop/presentation/bloc/shop_list_bloc.dart';

import '../widgets/category_slider.dart';
import '../widgets/featured_shops_carousel.dart';
import '../widgets/nearby_shops_section.dart';
import '../widgets/search_bar.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    // Load featured shops
    context.read<ShopListBloc>().add(const ShopListLoadFeaturedEvent());
    
    // Load nearby shops with default location
    // In a real app, you'd get the user's actual location
    context.read<ShopListBloc>().add(const ShopListLoadNearbyEvent(
      latitude: 37.7749, // Default to San Francisco
      longitude: -122.4194,
    ));
  }
  
  // Helper to get the current user from auth bloc
  User? _getCurrentUser(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      return authState.user;
    }
    return null;
  }
  
  // Helper to get first name from full name
  String _getFirstName(String fullName) {
    return fullName.split(' ').first;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = _getCurrentUser(context);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            context.read<ShopListBloc>().add(const ShopListLoadFeaturedEvent());
            context.read<ShopListBloc>().add(const ShopListLoadNearbyEvent(
              latitude: 37.7749,
              longitude: -122.4194,
            ));
            await Future.delayed(const Duration(milliseconds: 500));
          },
          child: CustomScrollView(
            slivers: [
              // App Bar
              SliverAppBar(
                floating: true,
                title: user != null
                    ? Text('Hello, ${_getFirstName(user.name)}')
                    : const Text('Delivery App'),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined),
                    onPressed: () {
                      // Navigate to notifications
                    },
                    tooltip: 'Notifications',
                  ),
                ],
              ),
              
              // Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Search Bar
                      HomeSearchBar(
                        onTap: () {
                          context.push('/search');
                        },
                      ),
                      const SizedBox(height: 24),
                      
                      // Categories
                      Text(
                        'Categories',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const CategorySlider(),
                      const SizedBox(height: 24),
                      
                      // Featured Shops
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Featured Shops',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              context.push('/shops');
                            },
                            child: const Text('See All'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const FeaturedShopsCarousel(),
                      const SizedBox(height: 24),
                      
                      // Nearby Shops
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Nearby Shops',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              context.push('/shops', extra: {'nearby': true});
                            },
                            child: const Text('See All'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const NearbyShopsSection(),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}