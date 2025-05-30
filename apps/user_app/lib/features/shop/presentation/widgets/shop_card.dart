import 'package:flutter/material.dart';
import 'package:domain/domain.dart';
import 'package:ui_kit/ui_kit.dart';

class ShopCard extends StatelessWidget {
  final Shop shop;
  final VoidCallback onTap;
  final bool isFeatured;

  const ShopCard({
    super.key,
    required this.shop,
    required this.onTap,
    this.isFeatured = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      contentPadding: EdgeInsets.zero,
      borderRadius: 16,
      selectable: true,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Shop Image
          Stack(
            children: [
              // Cover Image
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                child: shop.coverImageUrl != null
                    ? Image.network(
                        shop.coverImageUrl!,
                        height: 140,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            Container(
                              height: 140,
                              width: double.infinity,
                              color: theme.colorScheme.surfaceContainerHighest,
                              child: const Icon(Icons.image_not_supported_outlined, size: 32),
                            ),
                      )
                    : Container(
                        height: 140,
                        width: double.infinity,
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: Icon(
                          _getCategoryIcon(shop.category),
                          size: 32,
                          color: theme.colorScheme.primary,
                        ),
                      ),
              ),
              
              // Featured badge
              if (isFeatured)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.star,
                          size: 16,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Featured',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              
              // Logo
              if (shop.logoUrl != null)
                Positioned(
                  bottom: -24,
                  left: 16,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: theme.colorScheme.surface,
                        width: 3,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Image.network(
                        shop.logoUrl!,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            Container(
                              width: 48,
                              height: 48,
                              color: theme.colorScheme.primary,
                              child: Icon(
                                _getCategoryIcon(shop.category),
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          
          // Shop Info
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Shop Name and rating
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        shop.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star,
                            size: 14,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            shop.rating.toStringAsFixed(1),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                
                // Shop address
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        shop.address,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                // Status and delivery info
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: shop.isOpen
                            ? Colors.green.shade100
                            : Colors.red.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        shop.isOpen ? 'Open' : 'Closed',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: shop.isOpen ? Colors.green.shade800 : Colors.red.shade800,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${shop.estimatedDeliveryTime} min',
                      style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                    Icon(
                      Icons.pedal_bike_outlined,
                      size: 14,
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '\$${shop.deliveryFee.toStringAsFixed(2)}',
                      style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  // Helper method to get an icon for each shop category
  IconData _getCategoryIcon(ShopCategory category) {
    switch (category) {
      case ShopCategory.restaurant:
        return Icons.restaurant;
      case ShopCategory.grocery:
        return Icons.local_grocery_store;
      case ShopCategory.pharmacy:
        return Icons.local_pharmacy;
      case ShopCategory.retail:
        return Icons.shopping_bag;
      case ShopCategory.other:
        return Icons.store;
    }
  }
}