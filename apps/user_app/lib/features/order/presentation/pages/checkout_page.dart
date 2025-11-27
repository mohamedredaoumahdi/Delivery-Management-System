import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:domain/domain.dart';
import 'package:user_app/features/cart/domain/cart_repository.dart';
import 'package:user_app/features/cart/presentation/bloc/cart_bloc.dart';
import 'package:user_app/features/order/presentation/bloc/order_bloc.dart';
import 'package:user_app/features/address/presentation/bloc/address_bloc.dart';
import 'package:user_app/features/address/presentation/bloc/address_event.dart';
import 'package:user_app/features/address/presentation/bloc/address_state.dart';
import 'package:user_app/features/payment_method/presentation/bloc/payment_method_bloc.dart';
import 'package:user_app/features/payment_method/presentation/bloc/payment_method_event.dart';
import 'package:user_app/features/payment_method/presentation/bloc/payment_method_state.dart';
import 'package:user_app/features/auth/presentation/bloc/auth_bloc.dart';

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
  final _notesController = TextEditingController();
  
  Address? _selectedAddress;
  String _selectedPaymentMethod = 'Cash on Delivery';
  UserPaymentMethod? _selectedSavedPaymentMethod;
  final List<String> _paymentMethods = [
    'Cash on Delivery',
    'Credit/Debit Card',
    'Digital Wallet',
  ];

  @override
  void initState() {
    super.initState();
    // Load user addresses and payment methods when page initializes
    context.read<AddressBloc>().add(const AddressLoadEvent());
    context.read<PaymentMethodBloc>().add(const PaymentMethodLoadEvent());
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  /// Extracts user-friendly message from AppException string
  /// Removes "AppException: " prefix and " (CODE)" suffix
  String _extractUserFriendlyMessage(String errorMessage) {
    String message = errorMessage;
    
    // Remove "AppException: " prefix if present
    if (message.startsWith('AppException: ')) {
      message = message.substring('AppException: '.length);
    }
    
    // Remove " (CODE)" suffix if present (e.g., " (VALIDATION_ERROR)")
    final codePattern = RegExp(r'\s*\([^)]+\)\s*$');
    message = message.replaceAll(codePattern, '');
    
    return message.trim();
  }

  void _handleAuthError() {
    // Clear any existing dialogs
    Navigator.of(context).popUntil((route) => route.isFirst);
    
    // Show login required dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Login Required'),
        content: const Text('Your session has expired. Please login to continue with your order.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go('/');
            },
            child: const Text('Go to Home'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go('/login');
            },
            child: const Text('Login'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final summary = widget.summary;

    if (summary == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Checkout')),
        body: const Center(
          child: Text('No order summary available'),
        ),
      );
    }

    return MultiBlocListener(
      listeners: [
        BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthUnauthenticated) {
              _handleAuthError();
            }
          },
        ),
        BlocListener<OrderBloc, OrderState>(
          listener: (context, state) {
            if (state is OrderPlaced) {
              // Clear cart after successful order placement
              context.read<CartBloc>().add(const CartClearEvent());
              
              // Navigate to orders page using context.go to update bottom navigation
              context.go('/orders');
            } else if (state is OrderError) {
              // Check if it's an authentication error
              if (state.message.toLowerCase().contains('unauthorized') || 
                  state.message.toLowerCase().contains('access denied') ||
                  state.message.toLowerCase().contains('no token')) {
                _handleAuthError();
                return;
              }
              
              // Extract user-friendly message (removes AppException prefix and error code)
              final userFriendlyMessage = _extractUserFriendlyMessage(state.message);
              
              // Show error dialog with user-friendly message
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Order Failed'),
                  content: Text(userFriendlyMessage),
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
        ),
        BlocListener<AddressBloc, AddressState>(
          listener: (context, state) {
            if (state is AddressError) {
              // Check if it's an authentication error
              if (state.message.toLowerCase().contains('unauthorized') || 
                  state.message.toLowerCase().contains('access denied') ||
                  state.message.toLowerCase().contains('no token')) {
                _handleAuthError();
                return;
              }
            } else if (state is AddressLoaded && state.addresses.isNotEmpty) {
              // Auto-select the default address if available
              final defaultAddress = state.addresses.firstWhere(
                (addr) => addr.isDefault,
                orElse: () => state.addresses.first,
              );
              if (_selectedAddress == null) {
                setState(() {
                  _selectedAddress = defaultAddress;
                });
              }
            } else if (state is AddressCreated) {
              // Reload addresses when a new one is created
              context.read<AddressBloc>().add(const AddressLoadEvent());
            }
          },
        ),
        BlocListener<PaymentMethodBloc, PaymentMethodState>(
          listener: (context, state) {
            if (state is PaymentMethodError) {
              // Check if it's an authentication error
              if (state.message.toLowerCase().contains('unauthorized') || 
                  state.message.toLowerCase().contains('access denied') ||
                  state.message.toLowerCase().contains('no token')) {
                _handleAuthError();
                return;
              }
            } else if (state is PaymentMethodLoaded && state.paymentMethods.isNotEmpty) {
              // Auto-select the default payment method if available
              final defaultPaymentMethod = state.paymentMethods.firstWhere(
                (method) => method.isDefault,
                orElse: () => state.paymentMethods.first,
              );
              if (_selectedSavedPaymentMethod == null) {
                setState(() {
                  _selectedSavedPaymentMethod = defaultPaymentMethod;
                  _selectedPaymentMethod = 'saved'; // Special value for saved payment methods
                });
              }
            }
          },
        ),
      ],
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
      backgroundColor: theme.colorScheme.surfaceContainerHighest,
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
      child: BlocBuilder<AddressBloc, AddressState>(
        builder: (context, state) {
          if (state is AddressLoading) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            );
          }

          if (state is AddressLoaded) {
            if (state.addresses.isEmpty) {
              return _buildNoAddressesFound(context);
            }

            return Column(
              children: [
                // Address Selection
                ...state.addresses.map((address) => _buildAddressOption(context, address)),
                
                const SizedBox(height: 16),
                
                // Add New Address Button
                _buildAddNewAddressButton(context),
              ],
            );
          }

          if (state is AddressError) {
            return _buildAddressError(context, state.message);
          }

          return _buildNoAddressesFound(context);
        },
      ),
    );
  }

  Widget _buildAddressOption(BuildContext context, Address address) {
    final theme = Theme.of(context);
    final isSelected = _selectedAddress?.id == address.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border.all(
          color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outline,
          width: isSelected ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: RadioListTile<Address>(
        title: Row(
          children: [
            Icon(
              _getAddressIcon(address.label),
              size: 20,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              address.label,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            if (address.isDefault) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha:0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Default',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            address.fullAddress,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        value: address,
        groupValue: _selectedAddress,
        onChanged: (value) {
          setState(() {
            _selectedAddress = value;
          });
        },
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  Widget _buildAddNewAddressButton(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(
          color: theme.colorScheme.primary,
          style: BorderStyle.solid,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextButton.icon(
        onPressed: () async {
          await context.push('/profile/addresses/add');
          // Reload addresses after returning from add page
          context.read<AddressBloc>().add(const AddressLoadEvent());
        },
        icon: Icon(
          Icons.add_location_outlined,
          color: theme.colorScheme.primary,
        ),
        label: Text(
          'Add New Address',
          style: TextStyle(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildNoAddressesFound(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      children: [
        Icon(
          Icons.location_off_outlined,
          size: 48,
          color: theme.colorScheme.primary.withValues(alpha:0.5),
        ),
        const SizedBox(height: 16),
        Text(
          'No delivery addresses found',
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Add your first delivery address to continue',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        AppButton(
          text: 'Add Address',
          onPressed: () async {
            await context.push('/profile/addresses/add');
            // Reload addresses after returning from add page
            context.read<AddressBloc>().add(const AddressLoadEvent());
          },
          variant: AppButtonVariant.primary,
          icon: Icons.add_location_outlined,
        ),
      ],
    );
  }

  Widget _buildAddressError(BuildContext context, String message) {
    final theme = Theme.of(context);
    
    return Column(
      children: [
        Icon(
          Icons.error_outline,
          size: 48,
          color: theme.colorScheme.error,
        ),
        const SizedBox(height: 16),
        Text(
          'Failed to load addresses',
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.error,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          message,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        AppButton(
          text: 'Try Again',
          onPressed: () {
            context.read<AddressBloc>().add(const AddressLoadEvent());
          },
          variant: AppButtonVariant.secondary,
          icon: Icons.refresh,
        ),
      ],
    );
  }

  IconData _getAddressIcon(String label) {
    switch (label.toLowerCase()) {
      case 'home':
        return Icons.home_outlined;
      case 'work':
        return Icons.work_outline;
      case 'school':
        return Icons.school_outlined;
      case 'gym':
        return Icons.fitness_center_outlined;
      case 'hospital':
        return Icons.local_hospital_outlined;
      default:
        return Icons.location_on_outlined;
    }
  }

  Widget _buildPaymentMethod(BuildContext context) {
    return AppCard(
      title: 'Payment Method',
      child: BlocBuilder<PaymentMethodBloc, PaymentMethodState>(
        builder: (context, state) {
          if (state is PaymentMethodLoading) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            );
          }

          return Column(
            children: [
              // Saved Payment Methods
              if (state is PaymentMethodLoaded && state.paymentMethods.isNotEmpty) ...[
                ...state.paymentMethods.map((method) => 
                  _buildSavedPaymentMethodOption(context, method)
                ),
                const SizedBox(height: 16),
                _buildAddPaymentMethodButton(context),
                const Divider(height: 32),
              ],
              
              // Default Payment Methods
              Text(
                'Other Payment Methods',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              
              ..._paymentMethods.map((method) => _buildDefaultPaymentMethodOption(context, method)),
              
              // Add New Payment Method Button (if no saved methods)
              if (state is! PaymentMethodLoaded || state.paymentMethods.isEmpty) ...[
                const SizedBox(height: 16),
                _buildAddPaymentMethodButton(context),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildSavedPaymentMethodOption(BuildContext context, UserPaymentMethod method) {
    final theme = Theme.of(context);
    final isSelected = _selectedSavedPaymentMethod?.id == method.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border.all(
          color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outline,
          width: isSelected ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: RadioListTile<UserPaymentMethod>(
        title: Row(
          children: [
            Icon(
              _getPaymentMethodIcon(method.type),
              size: 20,
              color: _getPaymentMethodColor(method.type),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
              method.displayName,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            if (method.isDefault) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha:0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Default',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
            if (method.isExpiringSoon) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha:0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Expires Soon',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.orange,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: method.cardLast4 != null
            ? Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '**** **** **** ${method.cardLast4}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              )
            : null,
        value: method,
        groupValue: _selectedSavedPaymentMethod,
        onChanged: (value) {
          setState(() {
            _selectedSavedPaymentMethod = value;
            _selectedPaymentMethod = 'saved'; // Special value for saved payment methods
          });
        },
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  Widget _buildAddPaymentMethodButton(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(
          color: theme.colorScheme.primary,
          style: BorderStyle.solid,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextButton.icon(
        onPressed: () async {
          await context.push('/profile/payment-methods/add');
          // Reload payment methods after returning from add page
          context.read<PaymentMethodBloc>().add(const PaymentMethodLoadEvent());
        },
        icon: Icon(
          Icons.add_card_outlined,
          color: theme.colorScheme.primary,
        ),
        label: Text(
          'Add New Payment Method',
          style: TextStyle(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  IconData _getPaymentMethodIcon(PaymentMethodType type) {
    switch (type) {
      case PaymentMethodType.creditCard:
      case PaymentMethodType.debitCard:
        return Icons.credit_card;
      case PaymentMethodType.paypal:
        return Icons.account_balance_wallet;
      case PaymentMethodType.applePay:
        return Icons.phone_iphone;
      case PaymentMethodType.googlePay:
        return Icons.smartphone;
      case PaymentMethodType.bankAccount:
        return Icons.account_balance;
    }
  }

  Color _getPaymentMethodColor(PaymentMethodType type) {
    switch (type) {
      case PaymentMethodType.creditCard:
      case PaymentMethodType.debitCard:
        return Colors.blue;
      case PaymentMethodType.paypal:
        return Colors.indigo;
      case PaymentMethodType.applePay:
        return Colors.grey[800]!;
      case PaymentMethodType.googlePay:
        return Colors.green;
      case PaymentMethodType.bankAccount:
        return Colors.teal;
    }
  }

  Widget _buildDefaultPaymentMethodOption(BuildContext context, String method) {
    final theme = Theme.of(context);
    final isSelected = _selectedPaymentMethod == method;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border.all(
          color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outline,
          width: isSelected ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: RadioListTile<String>(
        title: Row(
          children: [
            Icon(
              _getDefaultPaymentMethodIcon(method),
              size: 20,
              color: _getDefaultPaymentMethodColor(method),
            ),
            const SizedBox(width: 8),
            Text(
              method,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        value: method,
        groupValue: _selectedPaymentMethod,
        onChanged: (value) {
          setState(() {
            _selectedPaymentMethod = value!;
            _selectedSavedPaymentMethod = null; // Clear saved payment method
          });
        },
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  IconData _getDefaultPaymentMethodIcon(String method) {
    switch (method) {
      case 'Cash on Delivery':
        return Icons.local_shipping_outlined;
      case 'Credit/Debit Card':
        return Icons.credit_card;
      case 'Digital Wallet':
        return Icons.account_balance_wallet;
      default:
        return Icons.payment;
    }
  }

  Color _getDefaultPaymentMethodColor(String method) {
    switch (method) {
      case 'Cash on Delivery':
        return Colors.green;
      case 'Credit/Debit Card':
        return Colors.blue;
      case 'Digital Wallet':
        return Colors.purple;
      default:
        return Colors.grey;
    }
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
            color: theme.colorScheme.shadow.withValues(alpha:0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: AppButton(
          text: 'Place Order - \$${summary.total.toStringAsFixed(2)}',
          onPressed: _selectedAddress != null ? _placeOrder : null,
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

    if (_selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a delivery address')),
      );
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

    // Convert payment method to enum
    PaymentMethod paymentMethod;
    
    if (_selectedPaymentMethod == 'saved' && _selectedSavedPaymentMethod != null) {
      // Use saved payment method
      switch (_selectedSavedPaymentMethod!.type) {
        case PaymentMethodType.creditCard:
        case PaymentMethodType.debitCard:
          paymentMethod = PaymentMethod.card;
          break;
        case PaymentMethodType.paypal:
        case PaymentMethodType.applePay:
        case PaymentMethodType.googlePay:
          paymentMethod = PaymentMethod.wallet;
          break;
        case PaymentMethodType.bankAccount:
          paymentMethod = PaymentMethod.bankTransfer;
          break;
      }
    } else {
      // Use traditional payment method
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
    }

    // Place the order using OrderBloc with selected address
    context.read<OrderBloc>().add(OrderPlaceEvent(
      shopId: shopId,
      items: orderItems,
      deliveryAddress: _selectedAddress!.fullAddress,
      deliveryLatitude: _selectedAddress!.latitude,
      deliveryLongitude: _selectedAddress!.longitude,
      deliveryInstructions: _notesController.text.trim().isNotEmpty 
          ? _notesController.text.trim() 
          : _selectedAddress!.instructions,
      paymentMethod: paymentMethod,
      tip: 0.0, // You might want to add a tip input field
    ));
  }
} 