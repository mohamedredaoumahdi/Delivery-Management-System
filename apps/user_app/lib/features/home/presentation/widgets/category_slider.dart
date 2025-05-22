import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:domain/domain.dart';

class CategorySlider extends StatelessWidget {
  const CategorySlider({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: ListView(
        scrollDirection: Axis.horizontal,
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
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                color: color,
                size: 32,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}