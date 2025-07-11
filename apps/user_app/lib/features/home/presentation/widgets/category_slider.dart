import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:domain/domain.dart';

class CategorySlider extends StatelessWidget {
  const CategorySlider({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 130,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        children: [
          _buildCategoryItem(
            context,
            'Restaurants',
            Icons.restaurant,
            Colors.orange.shade700,
            ShopCategory.restaurant,
          ),
          _buildCategoryItem(
            context,
            'Grocery',
            Icons.local_grocery_store,
            Colors.green.shade700,
            ShopCategory.grocery,
          ),
          _buildCategoryItem(
            context,
            'Pharmacy',
            Icons.local_pharmacy,
            Colors.red.shade700,
            ShopCategory.pharmacy,
          ),
          _buildCategoryItem(
            context,
            'Retail',
            Icons.shopping_bag,
            Colors.blue.shade700,
            ShopCategory.retail,
          ),
          _buildCategoryItem(
            context,
            'Other',
            Icons.more_horiz,
            Colors.purple.shade700,
            ShopCategory.other,
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryItem(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    ShopCategory category,
  ) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () {
        context.push('/shops', extra: {'category': category});
      },
      child: Container(
        width: 100,
        margin: const EdgeInsets.only(right: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    color.withOpacity(0.15),
                    color.withOpacity(0.08),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.15),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                    spreadRadius: 0,
                  ),
                  BoxShadow(
                    color: theme.colorScheme.shadow.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                    spreadRadius: 0,
                  ),
                ],
                border: Border.all(
                  color: color.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Stack(
                children: [
                  // Gradient overlay
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(19),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white.withOpacity(0.1),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Icon
                  Center(
                    child: Icon(
                      icon,
                      color: color,
                      size: 32,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}