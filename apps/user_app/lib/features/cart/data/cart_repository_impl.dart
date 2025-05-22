import 'dart:async';
import 'dart:convert';

import 'package:core/core.dart';
import 'package:domain/domain.dart';

import '../domain/cart_repository.dart';

class CartRepositoryImpl implements CartRepository {
  static const String _cartItemsKey = 'cart_items';
  
  final StorageService _storageService;
  final LoggerService _logger;
  
  final StreamController<List<CartItem>> _cartItemsController = 
    StreamController<List<CartItem>>.broadcast();
  
  final StreamController<CartSummary> _cartSummaryController = 
    StreamController<CartSummary>.broadcast();
  
  CartRepositoryImpl({
    required StorageService storageService,
    required LoggerService logger,
  }) : _storageService = storageService,
       _logger = logger;
       
  @override
  Stream<List<CartItem>> get cartItemsStream => _cartItemsController.stream;
  
  @override
  Stream<CartSummary> get cartSummaryStream => _cartSummaryController.stream;
  
  @override
  Future<List<CartItem>> getCartItems() async {
    try {
      final cartItemsString = _storageService.getString(_cartItemsKey);
      
      if (cartItemsString == null) {
        return [];
      }
      
      final cartItemsList = jsonDecode(cartItemsString) as List<dynamic>;
      final cartItems = cartItemsList
        .map((item) => _decodeCartItem(item))
        .toList();
      
      _cartItemsController.add(cartItems);
      return cartItems;
    } catch (e) {
      _logger.e('Error getting cart items', e);
      return [];
    }
  }
  
  @override
  Future<void> addToCart({
    required Product product,
    required String shopId,
    required String shopName,
    required int quantity,
    String? instructions,
  }) async {
    try {
      // Get current cart items
      final currentItems = await getCartItems();
      
      // Check if the product is already in the cart
      final existingItemIndex = currentItems.indexWhere(
        (item) => item.productId == product.id,
      );
      
      List<CartItem> updatedItems;
      
      if (existingItemIndex != -1) {
        // Update existing item
        final existingItem = currentItems[existingItemIndex];
        final updatedItem = existingItem.copyWith(
          quantity: existingItem.quantity + quantity,
          instructions: instructions != null ? () => instructions : null,
        );
        
        updatedItems = List.from(currentItems);
        updatedItems[existingItemIndex] = updatedItem;
      } else {
        // Add new item
        final newItem = CartItem.fromProduct(
          product: product,
          shopId: shopId,
          shopName: shopName,
          quantity: quantity,
          instructions: instructions,
        );
        
        updatedItems = List.from(currentItems)..add(newItem);
      }
      
      // Save updated cart
      await _saveCartItems(updatedItems);
      
      _logger.i('Product added to cart: ${product.name}');
    } catch (e) {
      _logger.e('Error adding product to cart', e);
      rethrow;
    }
  }
  
  @override
  Future<void> updateCartItemQuantity({
    required String productId,
    required int quantity,
  }) async {
    try {
      if (quantity <= 0) {
        await removeFromCart(productId);
        return;
      }
      
      final currentItems = await getCartItems();
      final itemIndex = currentItems.indexWhere(
        (item) => item.productId == productId,
      );
      
      if (itemIndex == -1) {
        throw Exception('Product not found in cart');
      }
      
      final updatedItem = currentItems[itemIndex].copyWith(
        quantity: quantity,
      );
      
      final updatedItems = List<CartItem>.from(currentItems);
      updatedItems[itemIndex] = updatedItem;
      
      await _saveCartItems(updatedItems);
      
      _logger.i('Cart item quantity updated: $productId, Quantity: $quantity');
    } catch (e) {
      _logger.e('Error updating cart item quantity', e);
      rethrow;
    }
  }
  
  @override
  Future<void> updateCartItemInstructions({
    required String productId,
    required String? instructions,
  }) async {
    try {
      final currentItems = await getCartItems();
      final itemIndex = currentItems.indexWhere(
        (item) => item.productId == productId,
      );
      
      if (itemIndex == -1) {
        throw Exception('Product not found in cart');
      }
      
      final updatedItem = currentItems[itemIndex].copyWith(
        instructions: () => instructions,
      );
      
      final updatedItems = List<CartItem>.from(currentItems);
      updatedItems[itemIndex] = updatedItem;
      
      await _saveCartItems(updatedItems);
      
      _logger.i('Cart item instructions updated: $productId');
    } catch (e) {
      _logger.e('Error updating cart item instructions', e);
      rethrow;
    }
  }
  
  @override
  Future<void> removeFromCart(String productId) async {
    try {
      final currentItems = await getCartItems();
      final updatedItems = currentItems.where(
        (item) => item.productId != productId,
      ).toList();
      
      await _saveCartItems(updatedItems);
      
      _logger.i('Product removed from cart: $productId');
    } catch (e) {
      _logger.e('Error removing product from cart', e);
      rethrow;
    }
  }
  
  @override
  Future<void> clearCart() async {
    try {
      await _storageService.remove(_cartItemsKey);
      
      // Update streams
      _cartItemsController.add([]);
      _cartSummaryController.add(CartSummary.empty());
      
      _logger.i('Cart cleared');
    } catch (e) {
      _logger.e('Error clearing cart', e);
      rethrow;
    }
  }
  
  @override
  Future<bool> isSingleShopCart() async {
    try {
      final items = await getCartItems();
      
      if (items.isEmpty) {
        return true;
      }
      
      final shopId = items.first.shopId;
      return items.every((item) => item.shopId == shopId);
    } catch (e) {
      _logger.e('Error checking if cart has single shop', e);
      return false;
    }
  }
  
  @override
  Future<String?> getCurrentShopId() async {
    try {
      final items = await getCartItems();
      
      if (items.isEmpty) {
        return null;
      }
      
      final isSingleShop = await isSingleShopCart();
      
      if (isSingleShop) {
        return items.first.shopId;
      } else {
        return null;
      }
    } catch (e) {
      _logger.e('Error getting current shop ID', e);
      return null;
    }
  }
  
  @override
  Future<CartSummary> getCartSummary({
    required double deliveryFee,
    required double serviceFee,
    required double taxRate,
  }) async {
    try {
      final items = await getCartItems();
      
      if (items.isEmpty) {
        return CartSummary.empty();
      }
      
      final subtotal = items.fold<double>(
        0, (sum, item) => sum + item.totalPrice,
      );
      
      final tax = subtotal * taxRate;
      final total = subtotal + deliveryFee + serviceFee + tax;
      final itemCount = items.length;
      final totalQuantity = items.fold<int>(
        0, (sum, item) => sum + item.quantity,
      );
      
      final summary = CartSummary(
        subtotal: subtotal,
        deliveryFee: deliveryFee,
        serviceFee: serviceFee,
        tax: tax,
        total: total,
        itemCount: itemCount,
        totalQuantity: totalQuantity,
      );
      
      _cartSummaryController.add(summary);
      
      return summary;
    } catch (e) {
      _logger.e('Error getting cart summary', e);
      return CartSummary.empty();
    }
  }
  
  // Private helper methods
  Future<void> _saveCartItems(List<CartItem> items) async {
    try {
      final encodedItems = items.map(_encodeCartItem).toList();
      final cartItemsString = jsonEncode(encodedItems);
      
      await _storageService.setString(_cartItemsKey, cartItemsString);
      
      // Update streams
      _cartItemsController.add(items);
      
      // Update cart summary with default values
      // Will be refreshed later with actual values when needed
      if (items.isNotEmpty) {
        final summary = await getCartSummary(
          deliveryFee: 3.99,  // Default values
          serviceFee: 1.99,   // Default values
          taxRate: 0.08,      // Default values
        );
        _cartSummaryController.add(summary);
      } else {
        _cartSummaryController.add(CartSummary.empty());
      }
    } catch (e) {
      _logger.e('Error saving cart items', e);
      rethrow;
    }
  }
  
  Map<String, dynamic> _encodeCartItem(CartItem item) {
    return {
      'productId': item.productId,
      'productName': item.productName,
      'productDescription': item.productDescription,
      'productImageUrl': item.productImageUrl,
      'productPrice': item.productPrice,
      'discountedPrice': item.discountedPrice,
      'shopId': item.shopId,
      'shopName': item.shopName,
      'quantity': item.quantity,
      'instructions': item.instructions,
    };
  }
  
  CartItem _decodeCartItem(Map<String, dynamic> map) {
    return CartItem(
      productId: map['productId'],
      productName: map['productName'],
      productDescription: map['productDescription'],
      productImageUrl: map['productImageUrl'],
      productPrice: map['productPrice'].toDouble(),
      discountedPrice: map['discountedPrice'] != null 
          ? map['discountedPrice'].toDouble() 
          : null,
      shopId: map['shopId'],
      shopName: map['shopName'],
      quantity: map['quantity'],
      instructions: map['instructions'],
    );
  }
  
  // Dispose resources
  void dispose() {
    _cartItemsController.close();
    _cartSummaryController.close();
    _logger.d('CartRepository disposed');
  }
}
