import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:domain/domain.dart';
import 'package:equatable/equatable.dart';

import '../domain/cart_repository.dart';

part 'cart_event.dart';
part 'cart_state.dart';

class CartBloc extends Bloc<CartEvent, CartState> {
  final CartRepository _cartRepository;
  
  StreamSubscription? _cartItemsSubscription;
  StreamSubscription? _cartSummarySubscription;
  
  CartBloc({
    required CartRepository cartRepository,
  }) : _cartRepository = cartRepository,
       super(const CartInitial()) {
    on<CartLoadEvent>(_onCartLoad);
    on<CartAddItemEvent>(_onCartAddItem);
    on<CartUpdateQuantityEvent>(_onCartUpdateQuantity);
    on<CartUpdateInstructionsEvent>(_onCartUpdateInstructions);
    on<CartRemoveItemEvent>(_onCartRemoveItem);
    on<CartClearEvent>(_onCartClear);
    on<CartUpdateSummaryEvent>(_onCartUpdateSummary);
    on<CartItemsUpdatedEvent>(_onCartItemsUpdated);
    on<CartSummaryUpdatedEvent>(_onCartSummaryUpdated);
    
    // Subscribe to cart changes
    _cartItemsSubscription = _cartRepository.cartItemsStream.listen((items) {
      add(CartItemsUpdatedEvent(items));
    });
    
    _cartSummarySubscription = _cartRepository.cartSummaryStream.listen((summary) {
      add(CartSummaryUpdatedEvent(summary));
    });
    
    // Load cart when the bloc is created
    add(const CartLoadEvent());
  }
  
  Future<void> _onCartLoad(
    CartLoadEvent event,
    Emitter<CartState> emit,
  ) async {
    emit(const CartLoading());
    
    try {
      final items = await _cartRepository.getCartItems();
      
      if (items.isEmpty) {
        emit(const CartEmpty());
      } else {
        final isSingleShop = await _cartRepository.isSingleShopCart();
        
        if (!isSingleShop) {
          emit(CartMultipleShops(items: items));
        } else {
          // Get cart summary with default values
          final summary = await _cartRepository.getCartSummary(
            deliveryFee: 3.99,  // Default values
            serviceFee: 1.99,   // Default values
            taxRate: 0.08,      // Default values
          );
          
          emit(CartLoaded(
            items: items,
            summary: summary,
          ));
        }
      }
    } catch (e) {
      emit(CartError('Failed to load cart: $e'));
    }
  }
  
  Future<void> _onCartAddItem(
    CartAddItemEvent event,
    Emitter<CartState> emit,
  ) async {
    final currentState = state;
    
    if (currentState is CartLoaded || currentState is CartEmpty) {
      emit(const CartLoading());
      
      try {
        // Check if adding from different shop
        final currentShopId = await _cartRepository.getCurrentShopId();
        
        if (currentShopId != null && currentShopId != event.shopId) {
          // Different shop - ask for confirmation
          emit(CartConfirmationNeeded(
            message: 'Adding items from a different shop will clear your current cart.',
            confirmCallback: () async {
              // Clear cart first, then add item
              await _cartRepository.clearCart();
              await _cartRepository.addToCart(
                product: event.product,
                shopId: event.shopId,
                shopName: event.shopName,
                quantity: event.quantity,
                instructions: event.instructions,
              );
              
              // Reload cart
              add(const CartLoadEvent());
            },
          ));
        } else {
          // Same shop or empty cart - add directly
          await _cartRepository.addToCart(
            product: event.product,
            shopId: event.shopId,
            shopName: event.shopName,
            quantity: event.quantity,
            instructions: event.instructions,
          );
          
          // Reload cart
          add(const CartLoadEvent());
        }
      } catch (e) {
        emit(CartError('Failed to add item to cart: $e'));
      }
    }
  }
  
  Future<void> _onCartUpdateQuantity(
    CartUpdateQuantityEvent event,
    Emitter<CartState> emit,
  ) async {
    if (state is CartLoaded) {
      emit(const CartLoading());
      
      try {
        await _cartRepository.updateCartItemQuantity(
          productId: event.productId,
          quantity: event.quantity,
        );
        
        // Reload cart
        add(const CartLoadEvent());
      } catch (e) {
        emit(CartError('Failed to update item quantity: $e'));
      }
    }
  }
  
  Future<void> _onCartUpdateInstructions(
    CartUpdateInstructionsEvent event,
    Emitter<CartState> emit,
  ) async {
    if (state is CartLoaded) {
      emit(const CartLoading());
      
      try {
        await _cartRepository.updateCartItemInstructions(
          productId: event.productId,
          instructions: event.instructions,
        );
        
        // Reload cart
        add(const CartLoadEvent());
      } catch (e) {
        emit(CartError('Failed to update item instructions: $e'));
      }
    }
  }
  
  Future<void> _onCartRemoveItem(
    CartRemoveItemEvent event,
    Emitter<CartState> emit,
  ) async {
    if (state is CartLoaded) {
      emit(const CartLoading());
      
      try {
        await _cartRepository.removeFromCart(event.productId);
        
        // Reload cart
        add(const CartLoadEvent());
      } catch (e) {
        emit(CartError('Failed to remove item from cart: $e'));
      }
    }
  }
  
  Future<void> _onCartClear(
    CartClearEvent event,
    Emitter<CartState> emit,
  ) async {
    emit(const CartLoading());
    
    try {
      await _cartRepository.clearCart();
      
      emit(const CartEmpty());
    } catch (e) {
      emit(CartError('Failed to clear cart: $e'));
    }
  }
  
  Future<void> _onCartUpdateSummary(
    CartUpdateSummaryEvent event,
    Emitter<CartState> emit,
  ) async {
    if (state is CartLoaded) {
      emit(const CartLoading());
      
      try {
        final summary = await _cartRepository.getCartSummary(
          deliveryFee: event.deliveryFee,
          serviceFee: event.serviceFee,
          taxRate: event.taxRate,
        );
        
        final items = await _cartRepository.getCartItems();
        
        emit(CartLoaded(
          items: items,
          summary: summary,
        ));
      } catch (e) {
        emit(CartError('Failed to update cart summary: $e'));
      }
    }
  }
  
  void _onCartItemsUpdated(
    CartItemsUpdatedEvent event,
    Emitter<CartState> emit,
  ) {
    // Items update coming from stream
    final currentState = state;
    
    if (currentState is CartLoaded) {
      emit(CartLoaded(
        items: event.items,
        summary: currentState.summary,
      ));
    } else if (event.items.isEmpty) {
      emit(const CartEmpty());
    } else if (currentState is! CartLoading) {
      // Only force a reload if we're not already loading
      add(const CartLoadEvent());
    }
  }
  
  void _onCartSummaryUpdated(
    CartSummaryUpdatedEvent event,
    Emitter<CartState> emit,
  ) {
    // Summary update coming from stream
    final currentState = state;
    
    if (currentState is CartLoaded) {
      emit(CartLoaded(
        items: currentState.items,
        summary: event.summary,
      ));
    }
  }
  
  @override
  Future<void> close() {
    _cartItemsSubscription?.cancel();
    _cartSummarySubscription?.cancel();
    return super.close();
  }
}