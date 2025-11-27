import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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

  Widget _buildInfoTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor,
    bool isClickable = false,
    VoidCallback? onTap,
  }) {
    final row = _buildEnhancedInfoRow(
      context,
      icon,
      label,
      value,
      iconColor,
      isClickable: isClickable,
      onTap: onTap,
    );

    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Colors.grey.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: row,
      ),
    );
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
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Loading dashboard...',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
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
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Section with gradient background
            _buildWelcomeCard(context, shop),
            
            const SizedBox(height: 30),
            
            // Status Overview Section
            Row(
              children: [
                Icon(
                  Icons.insights,
                  color: Theme.of(context).colorScheme.primary,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Text(
                  'Status Overview',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: _buildStatusGrid(context, shop),
            ),
            
            // Quick Actions section temporarily disabled
            // (kept here for future use)
            // const SizedBox(height: 32),
            // Row(
            //   children: [
            //     Icon(
            //       Icons.dashboard_customize,
            //       color: Theme.of(context).colorScheme.primary,
            //       size: 24,
            //     ),
            //     const SizedBox(width: 8),
            //     Text(
            //       'Quick Actions',
            //       style: Theme.of(context).textTheme.titleLarge?.copyWith(
            //             fontWeight: FontWeight.bold,
            //           ),
            //     ),
            //   ],
            // ),
            // const SizedBox(height: 16),
            // Row(
            //   children: [
            //     Expanded(
            //       child: _buildQuickActionItem(
            //         context,
            //         title: 'Manage Menu',
            //         icon: Icons.restaurant_menu,
            //         color: Colors.orange,
            //         onTap: () => _navigateToTab?.call(1),
            //       ),
            //     ),
            //     const SizedBox(width: 12),
            //     Expanded(
            //       child: _buildQuickActionItem(
            //         context,
            //         title: 'View Orders',
            //         icon: Icons.receipt_long,
            //         color: Colors.blue,
            //         onTap: () => _navigateToTab?.call(2),
            //       ),
            //     ),
            //     const SizedBox(width: 12),
            //     Expanded(
            //       child: _buildQuickActionItem(
            //         context,
            //         title: 'Analytics',
            //         icon: Icons.analytics,
            //         color: Colors.purple,
            //         onTap: () => _navigateToTab?.call(3),
            //       ),
            //     ),
            //     const SizedBox(width: 12),
            //     Expanded(
            //       child: _buildQuickActionItem(
            //         context,
            //         title: 'Settings',
            //         icon: Icons.settings,
            //         color: Colors.grey,
            //         onTap: () => _showShopSettingsDialog(context, shop),
            //       ),
            //     ),
            //   ],
            // ),
            
            const SizedBox(height: 24),
            
            // Business Information Section
            Row(
              children: [
                Icon(
                  Icons.business_center,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Business Information',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildInfoTile(
              context,
              icon: Icons.location_on,
              label: 'Address',
              value: shop['address'] ?? 'Not set',
              iconColor: Colors.red,
            ),
            _buildInfoTile(
              context,
              icon: Icons.phone,
              label: 'Phone',
              value: shop['phone'] ?? 'Not set',
              iconColor: Colors.green,
              isClickable: shop['phone'] != null,
              onTap: shop['phone'] != null
                  ? () {
                      // TODO: Implement phone call
                    }
                  : null,
            ),
            _buildInfoTile(
              context,
              icon: Icons.email,
              label: 'Email',
              value: shop['email'] ?? 'Not set',
              iconColor: Colors.blue,
              isClickable: shop['email'] != null,
              onTap: shop['email'] != null
                  ? () {
                      // TODO: Implement email
                    }
                  : null,
            ),
            _buildInfoTile(
              context,
              icon: Icons.language,
              label: 'Website',
              value: shop['website'] ?? 'Not set',
              iconColor: Colors.purple,
              isClickable: shop['website'] != null,
              onTap: shop['website'] != null
                  ? () {
                      // TODO: Implement website opening
                    }
                  : null,
            ),
            
            const SizedBox(height: 24),
            
            // Operating Hours Section
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Operating Hours',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 0,
              color: Theme.of(context).colorScheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: Colors.grey.withValues(alpha: 0.15),
                  width: 1,
                ),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildOperatingHoursContent(shop['openingHours']),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Pricing Information Section
            Row(
              children: [
                Icon(
                  Icons.attach_money,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Pricing Information',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: _buildPricingItem(
                      context,
                      Icons.shopping_cart,
                      'Min Order',
                      shop['minimumOrderAmount'] != null
                          ? '\$${shop['minimumOrderAmount'].toStringAsFixed(2)}'
                          : 'Not set',
                      Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildPricingItem(
                      context,
                      Icons.delivery_dining,
                      'Delivery Fee',
                      shop['deliveryFee'] != null
                          ? '\$${shop['deliveryFee'].toStringAsFixed(2)}'
                          : 'Not set',
                      Colors.teal,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20), // Bottom padding for scroll
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard(BuildContext context, Map<String, dynamic> shop) {
    final isOpen = shop['isOpen'] == true;
    final statusColor = isOpen ? Colors.green : Colors.orange;
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
              child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Container(
                padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.store,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
                child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  Text(
                    'Welcome back!',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    shop['name'] ?? 'Your Restaurant',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isOpen ? 'Currently Open' : 'Currently Closed',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                  ],
                ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusGrid(BuildContext context, Map<String, dynamic> shop) {
    return Wrap(
      alignment: WrapAlignment.start,
      spacing: 20,
      runSpacing: 20,
      children: [
        _buildStatusItem(
          context,
          'Shop Status',
          shop['isActive'] == true ? 'Active' : 'Inactive',
          shop['isActive'] == true ? Colors.green : Colors.orange,
          shop['isActive'] == true ? Icons.check_circle : Icons.warning,
        ),
        _buildStatusItem(
          context,
          'Rating',
          '${shop['rating']?.toStringAsFixed(1) ?? '0.0'}',
          Colors.amber,
          Icons.star,
        ),
        _buildStatusItem(
          context,
          'Delivery',
          shop['hasDelivery'] == true ? 'Available' : 'Unavailable',
          shop['hasDelivery'] == true ? Colors.blue : Colors.grey,
          Icons.delivery_dining,
        ),
        _buildStatusItem(
          context,
          'Pickup',
          shop['hasPickup'] == true ? 'Available' : 'Unavailable',
          shop['hasPickup'] == true ? Colors.purple : Colors.grey,
          Icons.store_mall_directory,
        ),
      ],
    );
  }

  Widget _buildStatusItem(
    BuildContext context,
    String label,
    String value,
    Color color,
    IconData icon, {
    String? subtitle,
  }) {
    return SizedBox(
      width: 150,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 22,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: color,
                        fontSize: 16,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                        fontSize: 11,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[500],
                          fontSize: 10,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedInfoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
    Color iconColor, {
    bool isClickable = false,
    VoidCallback? onTap,
  }) {
    final widget = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 20,
            color: iconColor,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isClickable
                          ? Theme.of(context).colorScheme.primary
                          : Colors.black87,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );

    if (isClickable && onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: widget,
        ),
      );
    }

    return widget;
  }

  Widget _buildPricingItem(
    BuildContext context,
    IconData icon,
    String label,
    String value,
    Color iconColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: iconColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  icon,
                  size: 16,
                  color: iconColor,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                  ),
                ),
              ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: iconColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionItem(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 22,
                color: color,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
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


  Widget _buildOperatingHoursContent(dynamic openingHours) {
    if (openingHours == null) {
      return const Text(
        'Not set',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      );
    }

    Map<String, dynamic>? hoursMap;
    
    // Parse JSON string if needed
    if (openingHours is String) {
      try {
        // Try to parse as JSON
        final decoded = openingHours.replaceAll('\\"', '"');
        if (decoded.startsWith('{') && decoded.endsWith('}')) {
          // It's a JSON string, parse it
          // Simple JSON parsing for this specific format
          hoursMap = _parseOpeningHoursJson(decoded);
        } else {
          // It's just a plain string
          return Text(
            openingHours,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          );
    }
      } catch (e) {
        // If parsing fails, show as string
        return Text(
          openingHours,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        );
      }
    } else if (openingHours is Map<String, dynamic>) {
      hoursMap = openingHours;
    } else {
      return Text(
        openingHours.toString(),
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      );
    }

    if (hoursMap == null || hoursMap.isEmpty) {
      return const Text(
        'Not set',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      );
    }

    // Format the hours nicely
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _formatHoursList(hoursMap),
    );
  }

  Map<String, dynamic>? _parseOpeningHoursJson(String jsonString) {
    try {
      // Remove outer quotes if present (from escaped JSON string)
      String cleaned = jsonString.trim();
      if (cleaned.startsWith('"') && cleaned.endsWith('"')) {
        cleaned = cleaned.substring(1, cleaned.length - 1);
      }
      
      // Unescape JSON string (handle \\" -> ")
      cleaned = cleaned.replaceAll('\\"', '"');
      
      // Try to parse as JSON
      final decoded = jsonDecode(cleaned) as Map<String, dynamic>;
      return decoded;
    } catch (e) {
      // If JSON parsing fails, try manual regex parsing as fallback
      try {
        final Map<String, dynamic> result = {};
        final dayPattern = RegExp(r'"(\w+)":\s*\{[^}]+\}');
        final matches = dayPattern.allMatches(jsonString);
        
        for (final match in matches) {
          final dayMatch = match.group(1);
          final dayData = match.group(0);
          
          if (dayMatch != null && dayData != null) {
            final openMatch = RegExp(r'"open":\s*"([^"]+)"').firstMatch(dayData);
            final closeMatch = RegExp(r'"close":\s*"([^"]+)"').firstMatch(dayData);
            
            if (openMatch != null && closeMatch != null) {
              result[dayMatch] = {
                'open': openMatch.group(1),
                'close': closeMatch.group(1),
              };
            }
          }
        }
        
        return result.isEmpty ? null : result;
      } catch (e2) {
        return null;
      }
    }
  }

  List<Widget> _formatHoursList(Map<String, dynamic> hoursMap) {
    final List<Widget> widgets = [];
    
    // Day order for display
    const dayOrder = [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday',
    ];
    
    // Day name mapping
    const dayNames = {
      'monday': 'Monday',
      'tuesday': 'Tuesday',
      'wednesday': 'Wednesday',
      'thursday': 'Thursday',
      'friday': 'Friday',
      'saturday': 'Saturday',
      'sunday': 'Sunday',
    };

    for (final day in dayOrder) {
        if (hoursMap.containsKey(day)) {
        final dayData = hoursMap[day];
        String openTime = '';
        String closeTime = '';
        
        if (dayData is Map) {
          openTime = dayData['open']?.toString() ?? '';
          closeTime = dayData['close']?.toString() ?? '';
        } else if (dayData is String) {
          // Try to extract times from string
          final times = dayData.split('-');
          if (times.length == 2) {
            openTime = times[0].trim();
            closeTime = times[1].trim();
    }
        }
        
        if (openTime.isNotEmpty && closeTime.isNotEmpty) {
          widgets.add(
            Container(
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Color(0xFFE5E5E5),
                    width: 0.6,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    dayNames[day] ?? day,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                  ),
                  Text(
                    '$openTime - $closeTime',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        } else {
          widgets.add(
            Container(
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Color(0xFFE5E5E5),
                    width: 0.6,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    dayNames[day] ?? day,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                  ),
                  Text(
                    'Closed',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[500],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      }
    }
    
    if (widgets.isEmpty) {
      widgets.add(
        const Text(
          'Not set',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }
    
    return widgets;
  }
} 