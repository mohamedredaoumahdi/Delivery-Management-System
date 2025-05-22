import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:user_app/features/cart/domain/cart_repository.dart';

import '../bloc/cart_bloc.dart';
import '../widgets/cart_item_card.dart';
import '../widgets/cart_summary_card.dart';
import '../widgets/empty_cart.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  @override
  void initState() {
    super.initState();
    context.read<CartBloc>().add(const CartLoadEvent());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Cart'),
        actions: [
          BlocBuilder<CartBloc, CartState>(
            builder: (context, state) {
              if (state is CartLoaded && state.items.isNotEmpty) {
                return IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _confirmClearCart(context),
                  tooltip: 'Clear Cart',
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: BlocConsumer<CartBloc, CartState>(
        listener: (context, state) {
          if (state is CartError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: theme.colorScheme.error,
              ),
            );
          } else if (state is CartConfirmationNeeded) {
            _showConfirmationDialog(
              context,
              state.message,
              state.confirmCallback,
            );
          }
        },
        builder: (context, state) {
          if (state is CartLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else if (state is CartEmpty) {
            return const EmptyCart();
          } else if (state is CartMultipleShops) {
            return _buildMultipleShopsWarning(context, state.items);
          } else if (state is CartLoaded) {
            return _buildCartContent(context, state);
          } else {
            return const Center(
              child: Text('Something went wrong'),
            );
          }
        },
      ),
    );
  }

  Widget _buildCartContent(BuildContext context, CartLoaded state) {
    if (state.items.isEmpty) {
      return const EmptyCart();
    }

    return Column(
      children: [
        // Items list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: state.items.length,
            itemBuilder: (context, index) {
              final item = state.items[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: CartItemCard(
                  item: item,
                  onIncrement: () {
                    context.read<CartBloc>().add(
                          CartUpdateQuantityEvent(
                            productId: item.productId,
                            quantity: item.quantity + 1,
                          ),
                        );
                  },
                  onDecrement: () {
                    if (item.quantity > 1) {
                      context.read<CartBloc>().add(
                            CartUpdateQuantityEvent(
                              productId: item.productId,
                              quantity: item.quantity - 1,
                            ),
                          );
                    }
                  },
                  onRemove: () {
                    context.read<CartBloc>().add(
                          CartRemoveItemEvent(
                            productId: item.productId,
                          ),
                        );
                  },
                  onUpdateInstructions: (instructions) {
                    context.read<CartBloc>().add(
                          CartUpdateInstructionsEvent(
                            productId: item.productId,
                            instructions: instructions,
                          ),
                        );
                  },
                ),
              );
            },
          ),
        ),
        
        // Summary and checkout button
        if (state.items.isNotEmpty)
          CartSummaryCard(
            summary: state.summary,
            onCheckout: () => _navigateToCheckout(context, state),
          ),
      ],
    );
  }

  Widget _buildMultipleShopsWarning(BuildContext context, List<CartItem> items) {
    // Group items by shop
    final Map<String, List<CartItem>> itemsByShop = {};
    for (final item in items) {
      if (!itemsByShop.containsKey(item.shopId)) {
        itemsByShop[item.shopId] = [];
      }
      itemsByShop[item.shopId]!.add(item);
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.orange,
          ),
          const SizedBox(height: 16),
          Text(
            'Items from Multiple Shops',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your cart contains items from multiple shops. We can only process orders from a single shop at a time.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          
          // List shops with their items
          Expanded(
            child: ListView.builder(
              itemCount: itemsByShop.length,
              itemBuilder: (context, index) {
                final shopId = itemsByShop.keys.elementAt(index);
                final shopItems = itemsByShop[shopId]!;
                final shopName = shopItems.first.shopName;
                
                return AppCard(
                  title: shopName,
                  subtitle: '${shopItems.length} ${shopItems.length == 1 ? 'item' : 'items'}',
                  selectable: true,
                  onTap: () => _keepShopItems(context, shopId),
                  trailing: TextButton(
                    onPressed: () => _keepShopItems(context, shopId),
                    child: const Text('Keep These'),
                  ),
                  child: Column(
                    children: shopItems
                        .map((item) => ListTile(
                              title: Text(item.productName),
                              subtitle: Text('Quantity: ${item.quantity}'),
                              leading: item.productImageUrl != null
                                  ? Image.network(
                                      item.productImageUrl!,
                                      width: 40,
                                      height: 40,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) =>
                                          const Icon(Icons.image_not_supported_outlined),
                                    )
                                  : const Icon(Icons.fastfood),
                            ))
                        .toList(),
                  ),
                );
              },
            ),
          ),
          
          const SizedBox(height: 16),
          AppButton(
            text: 'Clear All Items',
            onPressed: () {
              context.read<CartBloc>().add(const CartClearEvent());
            },
            variant: AppButtonVariant.outline,
            fullWidth: true,
          ),
        ],
      ),
    );
  }

  void _keepShopItems(BuildContext context, String shopIdToKeep) {
    // Show confirmation
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Keep Only These Items?'),
        content: const Text(
          'This will remove all items from other shops from your cart. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              
              // Get all items
              final state = context.read<CartBloc>().state;
              if (state is CartMultipleShops) {
                // Clear cart first
                context.read<CartBloc>().add(const CartClearEvent());
                
                // Then add back only items from the selected shop
                final itemsToKeep = state.items
                    .where((item) => item.shopId == shopIdToKeep)
                    .toList();
                
                // Re-add those items one by one
                for (final item in itemsToKeep) {
                  // We need to recreate the product to add
                  final product = Product(
                    id: item.productId,
                    name: item.productName,
                    description: item.productDescription,
                    price: item.productPrice,
                    discountedPrice: item.discountedPrice,
                    imageUrl: item.productImageUrl,
                    category: 'Unknown', // Not important for cart re-add
                    inStock: true,
                    shopId: item.shopId,
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  );
                  
                  context.read<CartBloc>().add(
                        CartAddItemEvent(
                          product: product,
                          shopId: item.shopId,
                          shopName: item.shopName,
                          quantity: item.quantity,
                          instructions: item.instructions,
                        ),
                      );
                }
              }
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _navigateToCheckout(BuildContext context, CartLoaded state) {
    // Navigate to checkout
    context.push('/checkout', extra: state.summary);
  }

  void _confirmClearCart(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Clear Cart?'),
        content: const Text(
          'This will remove all items from your cart. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<CartBloc>().add(const CartClearEvent());
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _showConfirmationDialog(
    BuildContext context,
    String message,
    Function confirmCallback,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirmation'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              confirmCallback();
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }
}