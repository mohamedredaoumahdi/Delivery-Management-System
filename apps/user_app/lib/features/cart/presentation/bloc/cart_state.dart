part of 'cart_bloc.dart';

abstract class CartState extends Equatable {
  const CartState();
  
  @override
  List<Object?> get props => [];
}

/// Initial state
class CartInitial extends CartState {
  const CartInitial();
}

/// Loading state
class CartLoading extends CartState {
  const CartLoading();
}

/// Empty cart state
class CartEmpty extends CartState {
  const CartEmpty();
}

/// Cart loaded successfully
class CartLoaded extends CartState {
  final List<CartItem> items;
  final CartSummary summary;

  const CartLoaded({
    required this.items,
    required this.summary,
  });

  @override
  List<Object> get props => [items, summary];
}

/// Cart contains items from multiple shops
class CartMultipleShops extends CartState {
  final List<CartItem> items;

  const CartMultipleShops({
    required this.items,
  });

  @override
  List<Object> get props => [items];
}

/// Cart error state
class CartError extends CartState {
  final String message;

  const CartError(this.message);

  @override
  List<Object> get props => [message];
}

/// Cart needs confirmation
class CartConfirmationNeeded extends CartState {
  final String message;
  final Function confirmCallback;

  const CartConfirmationNeeded({
    required this.message,
    required this.confirmCallback,
  });

  @override
  List<Object> get props => [message];
}