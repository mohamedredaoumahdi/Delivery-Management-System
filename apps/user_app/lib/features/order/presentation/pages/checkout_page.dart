import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:domain/domain.dart';
import 'package:user_app/features/cart/domain/cart_repository.dart';
import 'package:user_app/features/cart/presentation/bloc/cart_bloc.dart';
import 'package:user_app/features/order/presentation/bloc/order_bloc.dart';

class CheckoutPage extends StatefulWidget {
  final CartSummary? summary;

  const CheckoutPage({
    super.key,
    this.summary,
  });

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();
  
  String _selectedPaymentMethod = 'Cash on Delivery';
  final List<String> _paymentMethods = [
    'Cash on Delivery',
    'Credit/Debit Card',
    'Digital Wallet',
  ];

  @override
  void dispose() {
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final summary = widget.summary;

    if (summary == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Checkout')),
        body: const Center(
          child: Text('No order summary available'),
        ),
      );
    }

    return BlocListener<OrderBloc, OrderState>(
      listener: (context, state) {
        print('🎧 CheckoutPage BlocListener received state: ${state.runtimeType}');
        
        if (state is OrderPlaced) {
          print('🎉 CheckoutPage: Order placed successfully!');
          
          // Clear cart first
          context.read<CartBloc>().add(const CartClearEvent());
          
          // Navigate to orders page using context.go to update bottom navigation
          print('🚀 CheckoutPage: Navigating to orders page...');
          context.go('/orders');
          print('✅ CheckoutPage: Navigation completed');
        } else if (state is OrderError) {
          print('❌ CheckoutPage: Order error received: ${state.message}');
          
          // Show error dialog
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Order Failed'),
              content: Text(state.message),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Checkout'),
          elevation: 0,
        ),
        body: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Order Summary
                      _buildOrderSummary(context, widget.summary!),
                      const SizedBox(height: 24),
                      
                      // Delivery Address
                      _buildDeliveryAddress(context),
                      const SizedBox(height: 24),
                      
                      // Payment Method
                      _buildPaymentMethod(context),
                      const SizedBox(height: 24),
                      
                      // Order Notes
                      _buildOrderNotes(context),
                    ],
                  ),
                ),
              ),
              
              // Place Order Button
              _buildPlaceOrderButton(context, widget.summary!),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderSummary(BuildContext context, CartSummary summary) {
    final theme = Theme.of(context);
    
    return AppCard(
      title: 'Order Summary',
      child: Column(
        children: [
          _buildSummaryRow('Subtotal', '\$${summary.subtotal.toStringAsFixed(2)}'),
          const SizedBox(height: 8),
          _buildSummaryRow('Delivery Fee', '\$${summary.deliveryFee.toStringAsFixed(2)}'),
          const SizedBox(height: 8),
          _buildSummaryRow('Service Fee', '\$${summary.serviceFee.toStringAsFixed(2)}'),
          const SizedBox(height: 8),
          _buildSummaryRow('Tax', '\$${summary.tax.toStringAsFixed(2)}'),
          const Divider(height: 24),
          _buildSummaryRow(
            'Total',
            '\$${summary.total.toStringAsFixed(2)}',
            isTotal: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    final theme = Theme.of(context);
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: isTotal
              ? theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)
              : theme.textTheme.bodyMedium,
        ),
        Text(
          value,
          style: isTotal
              ? theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)
              : theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildDeliveryAddress(BuildContext context) {
    return AppCard(
      title: 'Delivery Address',
      child: TextFormField(
        controller: _addressController,
        decoration: const InputDecoration(
          hintText: 'Enter your delivery address',
          border: OutlineInputBorder(),
        ),
        maxLines: 3,
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Please enter your delivery address';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildPaymentMethod(BuildContext context) {
    return AppCard(
      title: 'Payment Method',
      child: Column(
        children: _paymentMethods.map((method) {
          return RadioListTile<String>(
            title: Text(method),
            value: method,
            groupValue: _selectedPaymentMethod,
            onChanged: (value) {
              setState(() {
                _selectedPaymentMethod = value!;
              });
            },
            contentPadding: EdgeInsets.zero,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildOrderNotes(BuildContext context) {
    return AppCard(
      title: 'Order Notes (Optional)',
      child: TextFormField(
        controller: _notesController,
        decoration: const InputDecoration(
          hintText: 'Any special instructions for your order',
          border: OutlineInputBorder(),
        ),
        maxLines: 2,
      ),
    );
  }

  Widget _buildPlaceOrderButton(BuildContext context, CartSummary summary) {
    final theme = Theme.of(context);
    
    return Container(
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
        child: AppButton(
          text: 'Place Order - \$${summary.total.toStringAsFixed(2)}',
          onPressed: _placeOrder,
          variant: AppButtonVariant.primary,
          size: AppButtonSize.large,
          fullWidth: true,
          icon: Icons.shopping_bag_outlined,
        ),
      ),
    );
  }

  void _placeOrder() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final cartState = context.read<CartBloc>().state;
    if (cartState is! CartLoaded || cartState.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your cart is empty')),
      );
      return;
    }

    // Convert cart items to order items
    final orderItems = cartState.items.map((cartItem) => OrderItem(
      productId: cartItem.productId,
      productName: cartItem.productName,
      productPrice: cartItem.productPrice,
      quantity: cartItem.quantity,
      totalPrice: cartItem.totalPrice,
      instructions: cartItem.instructions,
    )).toList();

    // Get shop ID from the first item (all items should be from the same shop)
    final shopId = cartState.items.first.shopId;

    // Convert payment method string to enum
    PaymentMethod paymentMethod;
    switch (_selectedPaymentMethod) {
      case 'Cash on Delivery':
        paymentMethod = PaymentMethod.cashOnDelivery;
        break;
      case 'Credit/Debit Card':
        paymentMethod = PaymentMethod.card;
        break;
      case 'Digital Wallet':
        paymentMethod = PaymentMethod.wallet;
        break;
      default:
        paymentMethod = PaymentMethod.cashOnDelivery;
    }

    // Place the order using OrderBloc
    context.read<OrderBloc>().add(OrderPlaceEvent(
      shopId: shopId,
      items: orderItems,
      deliveryAddress: _addressController.text.trim(),
      deliveryLatitude: 37.7749, // Default coordinates - you might want to get actual location
      deliveryLongitude: -122.4194,
      deliveryInstructions: _notesController.text.trim().isNotEmpty 
          ? _notesController.text.trim() 
          : null,
      paymentMethod: paymentMethod,
      tip: 0.0, // You might want to add a tip input field
    ));
  }
} 