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

    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.surface,
            theme.colorScheme.surface.withOpacity(0.9),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
      onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Shop Image
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
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
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        theme.colorScheme.primary.withOpacity(0.1),
                                        theme.colorScheme.primary.withOpacity(0.05),
                                      ],
                                    ),
                                  ),
                          child: Icon(
                            _getCategoryIcon(shop.category),
                            color: theme.colorScheme.primary,
                                    size: 28,
                          ),
                        ),
                  )
                : Container(
                    width: 70,
                    height: 70,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  theme.colorScheme.primary.withOpacity(0.1),
                                  theme.colorScheme.primary.withOpacity(0.05),
                                ],
                              ),
                            ),
                    child: Icon(
                      _getCategoryIcon(shop.category),
                      color: theme.colorScheme.primary,
                              size: 28,
                            ),
                    ),
                  ),
          ),
                const SizedBox(width: 16),
          
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
                                color: theme.colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.amber.shade100,
                                  Colors.amber.shade50,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: Colors.amber.shade200,
                                width: 0.5,
                              ),
                            ),
                            child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.star,
                                  size: 14,
                          color: Colors.amber,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          shop.rating.toStringAsFixed(1),
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                                    color: Colors.amber.shade800,
                          ),
                        ),
                      ],
                            ),
                    ),
                  ],
                ),
                      const SizedBox(height: 6),
                
                // Shop Category and Address
                Row(
                  children: [
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Icon(
                      _getCategoryIcon(shop.category),
                              size: 12,
                              color: theme.colorScheme.primary,
                            ),
                    ),
                          const SizedBox(width: 6),
                    Text(
                      _getCategoryName(shop.category),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.8),
                              fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.location_on_outlined,
                            size: 12,
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
                
                // Status and Info
                Row(
                  children: [
                    // Open/Closed Tag
                    Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: shop.isOpen
                                    ? [
                                        Colors.green.shade100,
                                        Colors.green.shade50,
                                      ]
                                    : [
                                        Colors.red.shade100,
                                        Colors.red.shade50,
                                      ],
                              ),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                        color: shop.isOpen
                                    ? Colors.green.shade200
                                    : Colors.red.shade200,
                                width: 0.5,
                              ),
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
                          _buildInfoChip(
                            context,
                          Icons.access_time,
                          '${shop.estimatedDeliveryTime} min',
                    ),
                    
                    const SizedBox(width: 8),
                    
                    // Delivery Fee
                          _buildInfoChip(
                            context,
                          Icons.pedal_bike_outlined,
                          '\$${shop.deliveryFee.toStringAsFixed(2)}',
                        ),
                      ],
                    ),
                  ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(BuildContext context, IconData icon, String text) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.2),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 3),
          Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.8),
              fontWeight: FontWeight.w500,
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