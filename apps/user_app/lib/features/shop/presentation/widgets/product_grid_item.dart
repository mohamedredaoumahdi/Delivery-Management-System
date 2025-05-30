// apps/user_app/lib/features/shop/presentation/widgets/product_grid_item.dart
import 'package:flutter/material.dart';
import 'package:domain/domain.dart';

class ProductGridItem extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  final VoidCallback onAddToCart;

  const ProductGridItem({
    super.key,
    required this.product,
    required this.onTap,
    required this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image
            Expanded(
              flex: 3,
              child: AspectRatio(
                aspectRatio: 1,
                child: product.imageUrl != null
                    ? Image.network(
                        product.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            Container(
                              color: theme.colorScheme.surfaceContainerHighest,
                              child: const Icon(
                                Icons.image_not_supported_outlined,
                                size: 32,
                              ),
                            ),
                      )
                    : Container(
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: const Icon(
                          Icons.fastfood,
                          size: 32,
                        ),
                      ),
              ),
            ),
            
            // Product info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product name and price
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            style: theme.textTheme.titleSmall,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              if (product.hasDiscount) ...[
                                Text(
                                  '\$${product.price.toStringAsFixed(2)}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    decoration: TextDecoration.lineThrough,
                                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '\$${product.activePrice.toStringAsFixed(2)}',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ] else
                                Text(
                                  '\$${product.price.toStringAsFixed(2)}',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    // Add to cart button
                    SizedBox(
                      width: double.infinity,
                      height: 26,
                      child: FilledButton.icon(
                        onPressed: product.inStock ? onAddToCart : null,
                        icon: const Icon(Icons.add_shopping_cart, size: 12),
                        label: const Text('Add', style: TextStyle(fontSize: 10)),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          minimumSize: const Size(0, 26),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}