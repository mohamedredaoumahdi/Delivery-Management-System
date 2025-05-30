import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:domain/domain.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:user_app/features/cart/presentation/bloc/cart_bloc.dart';

import '../bloc/product_details_bloc.dart';

class ProductDetailsPage extends StatefulWidget {
  final String shopId;
  final String productId;

  const ProductDetailsPage({
    super.key,
    required this.shopId,
    required this.productId,
  });

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  late TextEditingController _instructionsController;
  late PageController _imagePageController;
  
  int _quantity = 1;
  int _currentImageIndex = 0;
  bool _isFavorite = false;
  
  @override
  void initState() {
    super.initState();
    
    _instructionsController = TextEditingController();
    _imagePageController = PageController();
    
    // Load product details
    context.read<ProductDetailsBloc>().add(
      ProductDetailsLoadEvent(widget.productId),
    );
  }

  @override
  void dispose() {
    _instructionsController.dispose();
    _imagePageController.dispose();
    super.dispose();
  }

  void _incrementQuantity() {
    setState(() {
      _quantity++;
    });
  }

  void _decrementQuantity() {
    if (_quantity > 1) {
      setState(() {
        _quantity--;
      });
    }
  }

  void _addToCart(Product product, String shopName) {
    context.read<CartBloc>().add(
      CartAddItemEvent(
        product: product,
        shopId: widget.shopId,
        shopName: shopName,
        quantity: _quantity,
        instructions: _instructionsController.text.trim().isNotEmpty 
            ? _instructionsController.text.trim() 
            : null,
      ),
    );

    // Check if widget is still mounted before showing snackbar
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${product.name} ${_quantity > 1 ? '(${_quantity}x) ' : ''}added to cart',
        ),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'View Cart',
          onPressed: () => context.go('/cart'),
        ),
      ),
    );
    
    // Don't automatically close the page - let user decide via the banner or back button
  }

  void _toggleFavorite() {
    setState(() {
      _isFavorite = !_isFavorite;
    });
    
    // TODO: Implement favorite functionality with backend
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isFavorite 
              ? 'Added to favorites' 
              : 'Removed from favorites',
        ),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: BlocConsumer<ProductDetailsBloc, ProductDetailsState>(
        listener: (context, state) {
          if (state is ProductDetailsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: theme.colorScheme.error,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is ProductDetailsLoading) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          if (state is ProductDetailsError) {
            return _buildErrorState(context, state.message);
          }

          if (state is ProductDetailsLoaded) {
            final product = state.product;
            final shop = state.shop;
            
            return _buildProductDetails(context, product, shop);
          }

          // Default loading state
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductDetails(BuildContext context, Product product, Shop shop) {
    final theme = Theme.of(context);
    final imageUrls = product.imageUrl != null ? [product.imageUrl!] : <String>[];

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App bar with product image
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: imageUrls.isNotEmpty
                  ? PageView.builder(
                      controller: _imagePageController,
                      onPageChanged: (index) {
                        setState(() {
                          _currentImageIndex = index;
                        });
                      },
                      itemCount: imageUrls.length,
                      itemBuilder: (context, index) {
                        return Image.network(
                          imageUrls[index],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                color: theme.colorScheme.surfaceContainerHighest,
                                child: const Icon(
                                  Icons.image_not_supported_outlined,
                                  size: 64,
                                ),
                              ),
                        );
                      },
                    )
                  : Container(
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: const Icon(
                        Icons.fastfood,
                        size: 64,
                      ),
                    ),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  _isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: _isFavorite ? Colors.red : null,
                ),
                onPressed: _toggleFavorite,
              ),
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: () {
                  // TODO: Implement share functionality
                },
              ),
            ],
          ),
          
          // Product content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image indicators
                  if (imageUrls.length > 1)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: imageUrls.asMap().entries.map((entry) {
                        return Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _currentImageIndex == entry.key
                                ? theme.colorScheme.primary
                                : theme.colorScheme.outline,
                          ),
                        );
                      }).toList(),
                    ),
                  
                  if (imageUrls.length > 1) const SizedBox(height: 16),
                  
                  // Product name and shop
                  Text(
                    product.name,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Shop name
                  InkWell(
                    onTap: () => context.push('/shops/${widget.shopId}'),
                    child: Row(
                      children: [
                        Icon(
                          Icons.store,
                          size: 16,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          shop.name,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 12,
                          color: theme.colorScheme.primary,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Price and discount
                  Row(
                    children: [
                      if (product.hasDiscount) ...[
                        Text(
                          '\$${product.price.toStringAsFixed(2)}',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            decoration: TextDecoration.lineThrough,
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '\$${product.activePrice.toStringAsFixed(2)}',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${product.discountPercentage!.toInt()}% OFF',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.red.shade800,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ] else
                        Text(
                          '\$${product.price.toStringAsFixed(2)}',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Availability status
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: product.inStock 
                          ? Colors.green.shade100 
                          : Colors.red.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          product.inStock ? Icons.check_circle : Icons.cancel,
                          size: 16,
                          color: product.inStock 
                              ? Colors.green.shade800 
                              : Colors.red.shade800,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          product.inStock ? 'In Stock' : 'Out of Stock',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: product.inStock 
                                ? Colors.green.shade800 
                                : Colors.red.shade800,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  if (product.stockQuantity != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Only ${product.stockQuantity} left in stock',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 24),
                  
                  // Description
                  if (product.description.isNotEmpty) ...[
                    Text(
                      'Description',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      product.description,
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 24),
                  ],
                  
                  // Categories and tags
                  if (product.tags.isNotEmpty) ...[
                    Text(
                      'Tags',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: product.tags.map((tag) {
                        return Chip(
                          label: Text(tag),
                          backgroundColor: theme.colorScheme.surfaceContainerHighest,
                          labelStyle: theme.textTheme.bodySmall,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                  ],
                  
                  // Nutritional information (if available)
                  if (product.nutritionalInfo != null && 
                      product.nutritionalInfo!.isNotEmpty) ...[
                    Text(
                      'Nutritional Information',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    AppCard(
                      child: Column(
                        children: product.nutritionalInfo!.entries.map((entry) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  entry.key,
                                  style: theme.textTheme.bodyMedium,
                                ),
                                Text(
                                  entry.value.toString(),
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  
                  // Special instructions
                  Text(
                    'Special Instructions (Optional)',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  AppInputField(
                    controller: _instructionsController,
                    hintText: 'Any special requests or modifications...',
                    maxLines: 3,
                    minLines: 2,
                  ),
                  const SizedBox(height: 24),
                  
                  // Quantity selector
                  Text(
                    'Quantity',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: theme.colorScheme.outline.withOpacity(0.5),
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove),
                              onPressed: _quantity > 1 ? _decrementQuantity : null,
                              style: IconButton.styleFrom(
                                foregroundColor: _quantity > 1 
                                    ? theme.colorScheme.primary 
                                    : theme.colorScheme.onSurface.withOpacity(0.4),
                              ),
                            ),
                            Container(
                              constraints: const BoxConstraints(minWidth: 40),
                              child: Text(
                                '$_quantity',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: _incrementQuantity,
                              style: IconButton.styleFrom(
                                foregroundColor: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'Total: \$${(product.activePrice * _quantity).toStringAsFixed(2)}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
      
      // Bottom bar with add to cart button
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.shadow.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              // Price display
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    Text(
                      '\$${(product.activePrice * _quantity).toStringAsFixed(2)}',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              
              // Add to cart button
              Expanded(
                flex: 2,
                child: AppButton(
                  text: product.inStock 
                      ? 'Add to Cart' 
                      : 'Out of Stock',
                  onPressed: product.inStock 
                      ? () => _addToCart(product, shop.name)
                      : null,
                  variant: AppButtonVariant.primary,
                  size: AppButtonSize.large,
                  fullWidth: true,
                  icon: product.inStock 
                      ? Icons.shopping_cart_outlined 
                      : Icons.block,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 80,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 24),
              Text(
                'Failed to load product',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 32),
              AppButton(
                text: 'Try Again',
                onPressed: () {
                  context.read<ProductDetailsBloc>().add(
                    ProductDetailsLoadEvent(widget.productId),
                  );
                },
                variant: AppButtonVariant.primary,
                icon: Icons.refresh,
              ),
            ],
          ),
        ),
      ),
    );
  }
}