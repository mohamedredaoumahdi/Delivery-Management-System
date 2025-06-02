import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../bloc/dashboard_bloc.dart';

class DashboardPage extends StatefulWidget {
  final Function(int)? navigateToTab;
  
  const DashboardPage({super.key, this.navigateToTab});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  Function(int)? get _navigateToTab => widget.navigateToTab;
  
  @override
  void initState() {
    super.initState();
    // Load dashboard data when page initializes
    context.read<DashboardBloc>().add(LoadDashboard());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<DashboardBloc>().add(LoadDashboard());
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: Implement notifications
            },
          ),
        ],
      ),
      body: BlocBuilder<DashboardBloc, DashboardState>(
        builder: (context, state) {
          if (state is DashboardLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          
          if (state is DashboardError) {
            // Handle "Shop not found" error - new vendor needs to create shop
            if (state.message.contains('Shop not found') || 
                state.message.contains('create your shop first')) {
              return _buildCreateShopPrompt(context);
            }
            
            // Other errors
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Unable to load dashboard',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.message,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      context.read<DashboardBloc>().add(LoadDashboard());
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          
          if (state is DashboardLoaded) {
            return _buildDashboardContent(context, state.dashboardData);
          }
          
          return const Center(
            child: Text('Welcome to your dashboard'),
          );
        },
      ),
    );
  }

  Widget _buildCreateShopPrompt(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.store_outlined,
              size: 80,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              'Welcome to your vendor dashboard!',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'To get started, you need to create your shop first. This will allow customers to find and order from your business.',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                _showCreateShopDialog(context);
              },
              icon: const Icon(Icons.add_business),
              label: const Text('Create My Shop'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                context.read<DashboardBloc>().add(LoadDashboard());
              },
              child: const Text('I already have a shop - Refresh'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardContent(BuildContext context, Map<String, dynamic> data) {
    final shop = data; // data is now the shop object directly
    
    return RefreshIndicator(
      onRefresh: () async {
        context.read<DashboardBloc>().add(LoadDashboard());
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Section with real shop data
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      child: const Icon(
                        Icons.store,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome back!',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            shop['name'] ?? 'Your Restaurant',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            shop['isOpen'] == true ? 'Currently Open' : 'Currently Closed',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: shop['isOpen'] == true ? Colors.green : Colors.orange,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Shop Status Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Shop Status',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatusItem(
                            'Status',
                            shop['isActive'] == true ? 'Active' : 'Inactive',
                            shop['isActive'] == true ? Colors.green : Colors.orange,
                            shop['isActive'] == true ? Icons.check_circle : Icons.warning,
                          ),
                        ),
                        Expanded(
                          child: _buildStatusItem(
                            'Rating',
                            '${shop['rating']?.toStringAsFixed(1) ?? '0.0'} ⭐',
                            Colors.amber,
                            Icons.star,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatusItem(
                            'Delivery',
                            shop['hasDelivery'] == true ? 'Available' : 'Not Available',
                            shop['hasDelivery'] == true ? Colors.blue : Colors.grey,
                            Icons.delivery_dining,
                          ),
                        ),
                        Expanded(
                          child: _buildStatusItem(
                            'Pickup',
                            shop['hasPickup'] == true ? 'Available' : 'Not Available',
                            shop['hasPickup'] == true ? Colors.purple : Colors.grey,
                            Icons.store_mall_directory,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Quick Actions
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _buildActionCard(
                    context,
                    'Manage Menu',
                    Icons.restaurant_menu,
                    () {
                      // Navigate to menu management using callback
                      _navigateToTab?.call(1);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionCard(
                    context,
                    'View Orders',
                    Icons.list_alt,
                    () {
                      // Navigate to orders using callback
                      _navigateToTab?.call(2);
                    },
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: _buildActionCard(
                    context,
                    'Analytics',
                    Icons.analytics_outlined,
                    () {
                      // Navigate to analytics using callback
                      _navigateToTab?.call(3);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionCard(
                    context,
                    'Shop Settings',
                    Icons.settings_outlined,
                    () {
                      _showShopSettingsDialog(context, shop);
                    },
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Business Information
            Text(
              'Business Information',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildInfoRow(Icons.location_on, 'Address', shop['address'] ?? 'Not set'),
                    _buildInfoRow(Icons.phone, 'Phone', shop['phone'] ?? 'Not set'),
                    _buildInfoRow(Icons.email, 'Email', shop['email'] ?? 'Not set'),
                    _buildInfoRow(Icons.language, 'Website', shop['website'] ?? 'Not set'),
                    _buildInfoRow(Icons.schedule, 'Operating Hours', 
                      _formatOpeningHours(shop['openingHours'])),
                    _buildInfoRow(Icons.attach_money, 'Min Order', 
                      shop['minimumOrderAmount'] != null 
                        ? '\$${shop['minimumOrderAmount'].toStringAsFixed(2)}'
                        : 'Not set'),
                    _buildInfoRow(Icons.delivery_dining, 'Delivery Fee', 
                      shop['deliveryFee'] != null 
                        ? '\$${shop['deliveryFee'].toStringAsFixed(2)}'
                        : 'Not set'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusItem(String label, String value, Color color, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Icon(
                icon,
                size: 32,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCreateShopDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Your Shop'),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Shop creation feature is coming soon!'),
              SizedBox(height: 16),
              Text('For now, you can create your shop by contacting our support team or through the web dashboard.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Navigate to shop creation form
            },
            child: const Text('Create Shop'),
          ),
        ],
      ),
    );
  }

  void _showShopSettingsDialog(BuildContext context, Map<String, dynamic> shop) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Shop Settings'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Current shop: ${shop['name'] ?? 'Unnamed Shop'}'),
              const SizedBox(height: 16),
              const Text('Shop settings and editing features are coming soon!'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _formatOpeningHours(dynamic openingHours) {
    if (openingHours == null) {
      return 'Not set';
    }
    
    // Handle String type (direct text)
    if (openingHours is String) {
      return openingHours;
    }
    
    // Handle Map type (structured hours)
    if (openingHours is Map<String, dynamic>) {
      String formattedHours = '';
      for (var entry in openingHours.entries) {
        formattedHours += '${entry.key}: ${entry.value}\n';
      }
      return formattedHours.trim();
    }
    
    // Fallback
    return openingHours.toString();
  }
} 