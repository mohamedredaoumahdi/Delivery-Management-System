import 'package:domain/domain.dart';
import 'package:equatable/equatable.dart';

/// Repository for managing the shopping cart
abstract class CartRepository {
  /// Get the current cart items
  Future<List<CartItem>> getCartItems();
  
  /// Add a product to the cart
  Future<void> addToCart({
    required Product product,
    required String shopId,
    required String shopName,
    required int quantity,
    String? instructions,
  });
  
  /// Update the quantity of a cart item
  Future<void> updateCartItemQuantity({
    required String productId,
    required int quantity,
  });
  
  /// Update the instructions for a cart item
  Future<void> updateCartItemInstructions({
    required String productId,
    required String? instructions,
  });
  
  /// Remove a product from the cart
  Future<void> removeFromCart(String productId);
  
  /// Clear the entire cart
  Future<void> clearCart();
  
  /// Check if all items in the cart are from the same shop
  Future<bool> isSingleShopCart();
  
  /// Get the current shop ID (if all items are from the same shop)
  Future<String?> getCurrentShopId();
  
  /// Get the cart summary (subtotal, delivery fee, etc.)
  Future<CartSummary> getCartSummary({
    required double deliveryFee,
    required double serviceFee,
    required double taxRate,
  });
  
  /// Get the stream of cart changes
  Stream<List<CartItem>> get cartItemsStream;
  
  /// Get the stream of cart summary changes
  Stream<CartSummary> get cartSummaryStream;
}

/// Represents an item in the shopping cart
class CartItem extends Equatable {
  /// Product ID
  final String productId;
  
  /// Product name
  final String productName;
  
  /// Product description
  final String productDescription;
  
  /// Product image URL
  final String? productImageUrl;
  
  /// Product price
  final double productPrice;
  
  /// Product discounted price (if applicable)
  final double? discountedPrice;
  
  /// Shop ID
  final String shopId;
  
  /// Shop name
  final String shopName;
  
  /// Quantity
  final int quantity;
  
  /// Special instructions for this item
  final String? instructions;

  /// Create a cart item
  const CartItem({
    required this.productId,
    required this.productName,
    required this.productDescription,
    this.productImageUrl,
    required this.productPrice,
    this.discountedPrice,
    required this.shopId,
    required this.shopName,
    required this.quantity,
    this.instructions,
  });

  /// Create a cart item from a product
  factory CartItem.fromProduct({
    required Product product,
    required String shopId,
    required String shopName,
    required int quantity,
    String? instructions,
  }) {
    return CartItem(
      productId: product.id,
      productName: product.name,
      productDescription: product.description,
      productImageUrl: product.imageUrl,
      productPrice: product.price,
      discountedPrice: product.discountedPrice,
      shopId: shopId,
      shopName: shopName,
      quantity: quantity,
      instructions: instructions,
    );
  }

  /// Get the current active price (discounted if available, otherwise regular)
  double get activePrice => discountedPrice ?? productPrice;
  
  /// Calculate the total price for this item
  double get totalPrice => activePrice * quantity;
  
  /// Create a copy of this cart item with updated fields
  CartItem copyWith({
    String? productId,
    String? productName,
    String? productDescription,
    String? Function()? productImageUrl,
    double? productPrice,
    double? Function()? discountedPrice,
    String? shopId,
    String? shopName,
    int? quantity,
    String? Function()? instructions,
  }) {
    return CartItem(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productDescription: productDescription ?? this.productDescription,
      productImageUrl: productImageUrl != null ? productImageUrl() : this.productImageUrl,
      productPrice: productPrice ?? this.productPrice,
      discountedPrice: discountedPrice != null ? discountedPrice() : this.discountedPrice,
      shopId: shopId ?? this.shopId,
      shopName: shopName ?? this.shopName,
      quantity: quantity ?? this.quantity,
      instructions: instructions != null ? instructions() : this.instructions,
    );
  }
  
  @override
  List<Object?> get props => [
    productId, productName, productDescription, productImageUrl,
    productPrice, discountedPrice, shopId, shopName, quantity, instructions,
  ];
}

/// Represents a summary of the shopping cart
class CartSummary extends Equatable {
  /// Subtotal (sum of all items)
  final double subtotal;
  
  /// Delivery fee
  final double deliveryFee;
  
  /// Service fee
  final double serviceFee;
  
  /// Tax amount
  final double tax;
  
  /// Total amount (subtotal + fees + tax)
  final double total;
  
  /// Number of items in the cart
  final int itemCount;
  
  /// Total quantity of all items
  final int totalQuantity;

  /// Create a cart summary
  const CartSummary({
    required this.subtotal,
    required this.deliveryFee,
    required this.serviceFee,
    required this.tax,
    required this.total,
    required this.itemCount,
    required this.totalQuantity,
  });

  /// Create an empty cart summary
  factory CartSummary.empty() {
    return const CartSummary(
      subtotal: 0,
      deliveryFee: 0,
      serviceFee: 0,
      tax: 0,
      total: 0,
      itemCount: 0,
      totalQuantity: 0,
    );
  }
  
  @override
  List<Object> get props => [
    subtotal, deliveryFee, serviceFee, tax, total, itemCount, totalQuantity,
  ];
}