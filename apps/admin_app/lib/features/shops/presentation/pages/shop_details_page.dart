import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../../common/widgets/admin_layout.dart';
import '../../data/models/shop_model.dart';
import '../bloc/shop_bloc.dart';
import '../bloc/shop_event.dart';
import '../bloc/shop_state.dart';

class ShopDetailsPage extends StatelessWidget {
  final String shopId;

  const ShopDetailsPage({super.key, required this.shopId});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth <= 800;
    final horizontalPadding = isMobile ? 16.0 : 24.0;

    return BlocProvider(
      create: (context) => GetIt.instance<ShopBloc>()..add(LoadShopDetails(shopId)),
      child: AdminLayout(
        showAppBar: false,
        body: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(horizontalPadding, 0, horizontalPadding, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: isMobile ? 16 : 24),
              _HeaderSection(shopId: shopId, isMobile: isMobile),
              SizedBox(height: isMobile ? 16 : 24),
              BlocBuilder<ShopBloc, ShopState>(
                builder: (context, state) {
                  if (state is ShopLoading) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(48.0),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  if (state is ShopError) {
                    return _ErrorCard(
                      message: state.message,
                      onRetry: () => context.read<ShopBloc>().add(LoadShopDetails(shopId)),
                    );
                  }

                  if (state is ShopDetailsLoaded) {
                    return _ShopDetailsContent(shop: state.shop, isMobile: isMobile);
                  }

                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderSection extends StatelessWidget {
  final String shopId;
  final bool isMobile;

  const _HeaderSection({
    required this.shopId,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/shops'),
          tooltip: 'Back to Shops',
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Shop Details',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontSize: isMobile ? 22 : 28,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'Shop ID: $shopId',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        ElevatedButton.icon(
          onPressed: () => context.go('/shops/$shopId/performance'),
          icon: const Icon(Icons.analytics),
          label: const Text('View Performance'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}

class _ShopDetailsContent extends StatelessWidget {
  final ShopModel shop;
  final bool isMobile;

  const _ShopDetailsContent({
    required this.shop,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Shop Information Card
        _ShopInfoCard(shop: shop, isMobile: isMobile),
        SizedBox(height: isMobile ? 16 : 24),
        
        // Contact & Location Card
        _ContactLocationCard(shop: shop, isMobile: isMobile),
        SizedBox(height: isMobile ? 16 : 24),
        
        // Business Details Card
        _BusinessDetailsCard(shop: shop, isMobile: isMobile),
      ],
    );
  }
}

class _ShopInfoCard extends StatelessWidget {
  final ShopModel shop;
  final bool isMobile;

  const _ShopInfoCard({
    required this.shop,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.primary.withOpacity(0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.store, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        shop.name,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: isMobile ? 20 : 24,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: shop.isActive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: shop.isActive ? Colors.green : Colors.red,
                              ),
                            ),
                            child: Text(
                              shop.isActive ? 'Active' : 'Inactive',
                              style: TextStyle(
                                color: shop.isActive ? Colors.green : Colors.red,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _getCategoryColor(shop.category).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _getCategoryName(shop.category),
                              style: TextStyle(
                                color: _getCategoryColor(shop.category),
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              shop.description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'RESTAURANT':
        return Colors.deepOrange;
      case 'GROCERY':
        return Colors.green;
      case 'PHARMACY':
        return Colors.blue;
      case 'RETAIL':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _getCategoryName(String category) {
    switch (category) {
      case 'RESTAURANT':
        return 'Restaurant';
      case 'GROCERY':
        return 'Grocery';
      case 'PHARMACY':
        return 'Pharmacy';
      case 'RETAIL':
        return 'Retail';
      default:
        return 'Other';
    }
  }
}

class _ContactLocationCard extends StatelessWidget {
  final ShopModel shop;
  final bool isMobile;

  const _ContactLocationCard({
    required this.shop,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.red),
                const SizedBox(width: 12),
                Text(
                  'Contact & Location',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: isMobile ? 18 : 20,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _InfoRow(icon: Icons.email, label: 'Email', value: shop.email),
            const SizedBox(height: 16),
            _InfoRow(icon: Icons.phone, label: 'Phone', value: shop.phone),
            const SizedBox(height: 16),
            _InfoRow(icon: Icons.location_on, label: 'Address', value: shop.address),
            if (shop.website != null && shop.website!.isNotEmpty) ...[
              const SizedBox(height: 16),
              _InfoRow(icon: Icons.language, label: 'Website', value: shop.website!),
            ],
          ],
        ),
      ),
    );
  }
}

class _BusinessDetailsCard extends StatelessWidget {
  final ShopModel shop;
  final bool isMobile;

  const _BusinessDetailsCard({
    required this.shop,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.business, color: Colors.blue),
                const SizedBox(width: 12),
                Text(
                  'Business Details',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: isMobile ? 18 : 20,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (isMobile)
              Column(
                children: [
                  _MetricTile('Rating', '${shop.rating.toStringAsFixed(1)} ⭐', Colors.amber),
                  const SizedBox(height: 12),
                  _MetricTile('Total Reviews', shop.ratingCount.toString(), Colors.blue),
                  const SizedBox(height: 12),
                  _MetricTile('Min Order', '\$${shop.minimumOrderAmount.toStringAsFixed(2)}', Colors.green),
                  const SizedBox(height: 12),
                  _MetricTile('Delivery Fee', '\$${shop.deliveryFee.toStringAsFixed(2)}', Colors.orange),
                  const SizedBox(height: 12),
                  _MetricTile('Est. Delivery', '${shop.estimatedDeliveryTime} min', Colors.purple),
                ],
              )
            else
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _MetricTile('Rating', '${shop.rating.toStringAsFixed(1)} ⭐', Colors.amber),
                  _MetricTile('Total Reviews', shop.ratingCount.toString(), Colors.blue),
                  _MetricTile('Min Order', '\$${shop.minimumOrderAmount.toStringAsFixed(2)}', Colors.green),
                  _MetricTile('Delivery Fee', '\$${shop.deliveryFee.toStringAsFixed(2)}', Colors.orange),
                  _MetricTile('Est. Delivery', '${shop.estimatedDeliveryTime} min', Colors.purple),
                ],
              ),
            const SizedBox(height: 24),
            Row(
              children: [
                _FeatureChip(
                  icon: Icons.delivery_dining,
                  label: 'Delivery',
                  enabled: shop.hasDelivery,
                ),
                const SizedBox(width: 12),
                _FeatureChip(
                  icon: Icons.shopping_bag,
                  label: 'Pickup',
                  enabled: shop.hasPickup,
                ),
                const SizedBox(width: 12),
                _FeatureChip(
                  icon: Icons.star,
                  label: 'Featured',
                  enabled: shop.isFeatured,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
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
              const SizedBox(height: 4),
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
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MetricTile(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool enabled;

  const _FeatureChip({
    required this.icon,
    required this.label,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: enabled ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: enabled ? Colors.green : Colors.grey,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: enabled ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: enabled ? Colors.green : Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorCard({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text(
                'Error loading shop details',
                style: TextStyle(color: Colors.red[700], fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


