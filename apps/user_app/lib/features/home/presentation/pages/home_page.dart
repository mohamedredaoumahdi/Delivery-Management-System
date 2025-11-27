import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:domain/domain.dart';
import 'package:user_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:user_app/features/shop/presentation/bloc/shop_list_bloc.dart';
import 'package:user_app/features/location/presentation/bloc/location_bloc.dart';

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
    
    // Request location permission and get user location
    context.read<LocationBloc>().add(LocationRequestPermission());
    
    // Fallback: Load nearby shops with default coordinates after a delay
    // This ensures shops are shown even if location permission is denied or takes time
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        // Only load if we haven't received location yet
        // The LocationBloc listener will override this if location is available
        context.read<ShopListBloc>().add(const ShopListLoadNearbyEvent(
          latitude: 37.7749, // San Francisco default
          longitude: -122.4194,
        ));
      }
    });
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

    return BlocListener<LocationBloc, LocationState>(
      listener: (context, locationState) {
        if (locationState is LocationLoaded) {
          // Load nearby shops with user's actual location
          context.read<ShopListBloc>().add(ShopListLoadNearbyEvent(
            latitude: locationState.latitude,
            longitude: locationState.longitude,
          ));
        } else if (locationState is LocationPermissionDenied) {
          // Show permission denied message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(locationState.message),
              backgroundColor: theme.colorScheme.error,
            ),
          );
          // Load nearby shops with default San Francisco coordinates as fallback
          context.read<ShopListBloc>().add(const ShopListLoadNearbyEvent(
            latitude: 37.7749,
            longitude: -122.4194,
          ));
        } else if (locationState is LocationError) {
          // Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(locationState.message),
              backgroundColor: theme.colorScheme.error,
            ),
          );
          // Load nearby shops with default San Francisco coordinates as fallback
          context.read<ShopListBloc>().add(const ShopListLoadNearbyEvent(
            latitude: 37.7749,
            longitude: -122.4194,
          ));
        }
      },
      child: _buildHomeContent(context, theme, user),
    );
  }

  Widget _buildHomeContent(BuildContext context, ThemeData theme, User? user) {

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            context.read<ShopListBloc>().add(const ShopListLoadFeaturedEvent());
            context.read<LocationBloc>().add(LocationGetCurrentLocation());
            await Future.delayed(const Duration(milliseconds: 500));
          },
          child: CustomScrollView(
            slivers: [
              // Header Section
              SliverToBoxAdapter(
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user != null
                                    ? 'Hello, ${_getFirstName(user.name)}! 👋'
                                    : 'Hello, Customer! 👋',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onSurface,
                                  fontSize: 24,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'What would you like to order today?',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        IconButton(
                          icon: Icon(
                            Icons.notifications_outlined,
                            color: theme.colorScheme.onSurface,
                            size: 28,
                          ),
                          iconSize: 28,
                          onPressed: () {
                            // Navigate to notifications
                          },
                          tooltip: 'Notifications',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Search Bar
                      const HomeSearchBar(),
                      const SizedBox(height: 32),
                      
                      // Categories
                      _buildSectionHeader(
                        context,
                        'Categories',
                        subtitle: 'Browse by type',
                      ),
                      const SizedBox(height: 20),
                      const CategorySlider(),
                      const SizedBox(height: 32),
                      
                      // Featured Shops
                      _buildSectionHeader(
                        context,
                            'Featured Shops',
                        subtitle: 'Handpicked for you',
                        onSeeAll: () {
                              context.push('/shops');
                            },
                      ),
                      const SizedBox(height: 20),
                      const FeaturedShopsCarousel(),
                      const SizedBox(height: 32),
                      
                      // Nearby Shops
                      _buildSectionHeader(
                        context,
                            'Nearby Shops',
                        subtitle: 'Quick delivery options',
                        onSeeAll: () {
                              context.push('/shops', extra: {'nearby': true});
                            },
                      ),
                      const SizedBox(height: 20),
                      const NearbyShopsSection(),
                      const SizedBox(height: 40),
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

  Widget _buildSectionHeader(
    BuildContext context,
    String title, {
    String? subtitle,
    VoidCallback? onSeeAll,
  }) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 28,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.primary.withValues(alpha:0.5),
                  ],
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha:0.6),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (onSeeAll != null)
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.colorScheme.primary.withValues(alpha:0.1),
                      theme.colorScheme.primary.withValues(alpha:0.05),
                    ],
                  ),
                ),
                child: TextButton(
                  onPressed: onSeeAll,
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'See All',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_forward_ios, size: 12),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}