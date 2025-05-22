part of 'cart_bloc.dart';

abstract class CartEvent extends Equatable {
  const CartEvent();

  @override
  List<Object?> get props => [];
}

/// Load the cart
class CartLoadEvent extends CartEvent {
  const CartLoadEvent();
}

/// Add an item to the cart
class CartAddItemEvent extends CartEvent {
  final Product product;
  final String shopId;
  final String shopName;
  final int quantity;
  final String? instructions;

  const CartAddItemEvent({
    required this.product,
    required this.shopId,
    required this.shopName,
    required this.quantity,
    this.instructions,
  });

  @override
  List<Object?> get props => [product, shopId, shopName, quantity, instructions];
}

/// Update the quantity of an item in the cart
class CartUpdateQuantityEvent extends CartEvent {
  final String productId;
  final int quantity;

  const CartUpdateQuantityEvent({
    required this.productId,
    required this.quantity,
  });

  @override
  List<Object> get props => [productId, quantity];
}

/// Update the instructions for an item in the cart
class CartUpdateInstructionsEvent extends CartEvent {
  final String productId;
  final String? instructions;

  const CartUpdateInstructionsEvent({
    required this.productId,
    required this.instructions,
  });

  @override
  List<Object?> get props => [productId, instructions];
}

/// Remove an item from the cart
class CartRemoveItemEvent extends CartEvent {
  final String productId;

  const CartRemoveItemEvent({
    required this.productId,
  });

  @override
  List<Object> get props => [productId];
}

/// Clear the cart
class CartClearEvent extends CartEvent {
  const CartClearEvent();
}

/// Update the cart summary
class CartUpdateSummaryEvent extends CartEvent {
  final double deliveryFee;
  final double serviceFee;
  final double taxRate;

  const CartUpdateSummaryEvent({
    required this.deliveryFee,
    required this.serviceFee,
    required this.taxRate,
  });

  @override
  List<Object> get props => [deliveryFee, serviceFee, taxRate];
}

/// Internal event used when cart items are updated from the stream
class CartItemsUpdatedEvent extends CartEvent {
  final List<CartItem> items;

  const CartItemsUpdatedEvent(this.items);

  @override
  List<Object> get props => [items];
}

/// Internal event used when cart summary is updated from the stream
class CartSummaryUpdatedEvent extends CartEvent {
  final CartSummary summary;

  const CartSummaryUpdatedEvent(this.summary);

  @override
  List<Object> get props => [summary];
}