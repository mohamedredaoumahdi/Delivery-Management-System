// apps/user_app/lib/features/shop/presentation/widgets/shop_info_card.dart
import 'package:flutter/material.dart';
import 'package:domain/domain.dart';

class ShopInfoCard extends StatelessWidget {
  final Shop shop;

  const ShopInfoCard({
    super.key,
    required this.shop,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Shop logo
                CircleAvatar(
                  radius: 24,
                  backgroundImage: shop.logoUrl != null
                      ? NetworkImage(shop.logoUrl!)
                      : null,
                  child: shop.logoUrl == null
                      ? const Icon(Icons.store)
                      : null,
                ),
                const SizedBox(width: 16),
                
                // Shop name and rating
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        shop.name,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.star,
                            size: 16,
                            color: Colors.amber,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            shop.rating.toStringAsFixed(1),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            ' (${shop.ratingCount})',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}