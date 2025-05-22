import 'package:flutter/material.dart';
import 'package:domain/domain.dart';
import 'package:ui_kit/ui_kit.dart';

class ShopListItem extends StatelessWidget {
  final Shop shop;
  final VoidCallback onTap;

  const ShopListItem({
    super.key,
    required this.shop,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      contentPadding: const EdgeInsets.all(12),
      borderRadius: 12,
      selectable: true,
      onTap: onTap,
      child: Row(
        children: [
          // Shop Image
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: shop.logoUrl != null
                ? Image.network(
                    shop.logoUrl!,
                    width: 70,
                    height: 70,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        Container(
                          width: 70,
                          height: 70,
                          color: theme.colorScheme.surfaceVariant,
                          child: Icon(
                            _getCategoryIcon(shop.category),
                            color: theme.colorScheme.primary,
                          ),
                        ),
                  )
                : Container(
                    width: 70,
                    height: 70,
                    color: theme.colorScheme.surfaceVariant,
                    child: Icon(
                      _getCategoryIcon(shop.category),
                      color: theme.colorScheme.primary,
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          
          // Shop Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Shop Name and Rating
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
                    // Rating
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.star,
                          size: 16,
                          color: Colors.amber,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          shop.rating.toStringAsFixed(1),
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                
                // Shop Category and Address
                Row(
                  children: [
                    Icon(
                      _getCategoryIcon(shop.category),
                      size: 14,
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _getCategoryName(shop.category),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(width: 8),
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
                const SizedBox(height: 6),
                
                // Status and Info
                Row(
                  children: [
                    // Open/Closed Tag
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
                    
                    const SizedBox(width: 8),
                    
                    // Delivery Time
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
                    
                    // Delivery Fee
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
  
  // Helper method to get a name for each shop category
  String _getCategoryName(ShopCategory category) {
    switch (category) {
      case ShopCategory.restaurant:
        return 'Restaurant';
      case ShopCategory.grocery:
        return 'Grocery';
      case ShopCategory.pharmacy:
        return 'Pharmacy';
      case ShopCategory.retail:
        return 'Retail';
      case ShopCategory.other:
        return 'Other';
    }
  }
}