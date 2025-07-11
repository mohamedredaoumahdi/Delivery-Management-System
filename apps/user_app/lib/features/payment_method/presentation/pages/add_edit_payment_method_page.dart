import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:domain/domain.dart';
import 'package:ui_kit/ui_kit.dart';

import '../bloc/payment_method_bloc.dart';
import '../bloc/payment_method_event.dart';
import '../bloc/payment_method_state.dart';

class AddEditPaymentMethodPage extends StatefulWidget {
  final String? paymentMethodId;

  const AddEditPaymentMethodPage({
    super.key,
    this.paymentMethodId,
  });

  @override
  State<AddEditPaymentMethodPage> createState() => _AddEditPaymentMethodPageState();
}

class _AddEditPaymentMethodPageState extends State<AddEditPaymentMethodPage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  // Controllers
  final _labelController = TextEditingController();
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _holderNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  
  // Form state
  PaymentMethodType _selectedType = PaymentMethodType.creditCard;
  String _selectedCardBrand = 'visa';
  bool _isDefault = false;
  bool _hasUnsavedChanges = false;
  
  // Editing state
  UserPaymentMethod? _existingPaymentMethod;
  bool get isEditing => widget.paymentMethodId != null;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _setupFormListeners();
    if (isEditing) {
      _loadExistingPaymentMethod();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _labelController.dispose();
    _cardNumberController.dispose();
    _expiryController.dispose();
    _holderNameController.dispose();
    _emailController.dispose();
    _bankNameController.dispose();
    _accountNumberController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));
    
    _animationController.forward();
  }

  void _setupFormListeners() {
    _labelController.addListener(() => _markAsChanged());
    _cardNumberController.addListener(() => _markAsChanged());
    _expiryController.addListener(() => _markAsChanged());
    _holderNameController.addListener(() => _markAsChanged());
    _emailController.addListener(() => _markAsChanged());
    _bankNameController.addListener(() => _markAsChanged());
    _accountNumberController.addListener(() => _markAsChanged());
  }

  void _markAsChanged() {
    if (!_hasUnsavedChanges) {
      setState(() => _hasUnsavedChanges = true);
    }
  }

  void _loadExistingPaymentMethod() {
    // TODO: Load existing payment method data when editing
    // For now, we'll handle this in the BLoC listener
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasUnsavedChanges,
      onPopInvoked: (didPop) {
        if (!didPop && _hasUnsavedChanges) {
          _showDiscardChangesDialog();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.black87,
          title: Text(
            isEditing ? 'Edit Payment Method' : 'Add Payment Method',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 16),
              child: TextButton(
                onPressed: _savePaymentMethod,
                style: TextButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                ),
                child: Text(
                  isEditing ? 'Update' : 'Save',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
        body: BlocConsumer<PaymentMethodBloc, PaymentMethodState>(
          listener: (context, state) {
            if (state is PaymentMethodCreated) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.white),
                      SizedBox(width: 12),
                      Text('Payment method added successfully'),
                    ],
                  ),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
              context.pop(true);
            } else if (state is PaymentMethodUpdated) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.white),
                      SizedBox(width: 12),
                      Text('Payment method updated successfully'),
                    ],
                  ),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
              context.pop(true);
            } else if (state is PaymentMethodError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.error, color: Colors.white),
                      const SizedBox(width: 12),
                      Expanded(child: Text(state.message)),
                    ],
                  ),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            }
          },
          builder: (context, state) {
            if (state is PaymentMethodLoading) {
              return const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              );
            }
            
            return FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildPaymentTypeSelector(),
                        const SizedBox(height: 32),
                        _buildFormCard(),
                        const SizedBox(height: 24),
                        _buildDefaultToggle(),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPaymentTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Payment Method Type',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 2.5,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: PaymentMethodType.values.map((type) {
              final isSelected = type == _selectedType;
              return GestureDetector(
                onTap: isEditing ? null : () => _selectPaymentType(type),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? LinearGradient(
                            colors: [
                              Theme.of(context).primaryColor,
                              Theme.of(context).primaryColor.withOpacity(0.8),
                            ],
                          )
                        : null,
                    color: isSelected ? null : Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected 
                          ? Theme.of(context).primaryColor 
                          : Colors.grey[300]!,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _getPaymentTypeIcon(type),
                        size: 24,
                        color: isSelected ? Colors.white : Colors.grey[600],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _getPaymentTypeLabel(type),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isSelected ? Colors.white : Colors.grey[700],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildFormCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabelField(),
          const SizedBox(height: 24),
          _buildPaymentSpecificFields(),
        ],
      ),
    );
  }

  Widget _buildLabelField() {
    return TextFormField(
      controller: _labelController,
      decoration: InputDecoration(
        labelText: 'Label',
        hintText: 'e.g., Personal Card, Business PayPal',
        prefixIcon: const Icon(Icons.label_outline),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).primaryColor),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter a label';
        }
        if (value.trim().length < 2) {
          return 'Label must be at least 2 characters';
        }
        return null;
      },
    );
  }

  Widget _buildPaymentSpecificFields() {
    switch (_selectedType) {
      case PaymentMethodType.creditCard:
      case PaymentMethodType.debitCard:
        return _buildCardFields();
      case PaymentMethodType.paypal:
        return _buildPayPalFields();
      case PaymentMethodType.applePay:
      case PaymentMethodType.googlePay:
        return _buildDigitalWalletFields();
      case PaymentMethodType.bankAccount:
        return _buildBankAccountFields();
    }
  }

  Widget _buildCardFields() {
    return Column(
      children: [
        TextFormField(
          controller: _cardNumberController,
          decoration: InputDecoration(
            labelText: 'Card Number',
            hintText: '1234 5678 9012 3456',
            prefixIcon: const Icon(Icons.credit_card),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Theme.of(context).primaryColor),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            _CardNumberInputFormatter(),
          ],
          validator: (value) {
            if (value == null || value.replaceAll(' ', '').length < 13) {
              return 'Please enter a valid card number';
            }
            return null;
          },
          onChanged: (value) => _detectCardBrand(value),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: _expiryController,
                decoration: InputDecoration(
                  labelText: 'Expiry Date',
                  hintText: 'MM/YY',
                  prefixIcon: const Icon(Icons.calendar_today),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Theme.of(context).primaryColor),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  _ExpiryDateInputFormatter(),
                ],
                validator: (value) {
                  if (value == null || value.length != 5) {
                    return 'Enter MM/YY format';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: DropdownButtonFormField<String>(
                  value: _selectedCardBrand,
                  decoration: const InputDecoration(
                    labelText: 'Card Brand',
                    prefixIcon: Icon(Icons.business),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  ),
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(value: 'visa', child: Text('Visa')),
                    DropdownMenuItem(value: 'mastercard', child: Text('Mastercard')),
                    DropdownMenuItem(value: 'amex', child: Text('Amex')),
                    DropdownMenuItem(value: 'discover', child: Text('Discover')),
                    DropdownMenuItem(value: 'other', child: Text('Other')),
                  ],
                  onChanged: (value) => setState(() => _selectedCardBrand = value!),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _holderNameController,
          decoration: InputDecoration(
            labelText: 'Cardholder Name',
            hintText: 'John Doe',
            prefixIcon: const Icon(Icons.person_outline),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Theme.of(context).primaryColor),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          textCapitalization: TextCapitalization.words,
          validator: (value) {
            if (value == null || value.trim().length < 2) {
              return 'Please enter the cardholder name';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildPayPalFields() {
    return TextFormField(
      controller: _emailController,
      decoration: InputDecoration(
        labelText: 'PayPal Email',
        hintText: 'your.email@example.com',
        prefixIcon: const Icon(Icons.email_outlined),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).primaryColor),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      keyboardType: TextInputType.emailAddress,
      validator: (value) {
        if (value == null || !value.contains('@')) {
          return 'Please enter a valid email address';
        }
        return null;
      },
    );
  }

  Widget _buildDigitalWalletFields() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor.withOpacity(0.1),
            Theme.of(context).primaryColor.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).primaryColor.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _selectedType == PaymentMethodType.applePay 
                ? Icons.phone_iphone 
                : Icons.smartphone,
              size: 48,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _selectedType == PaymentMethodType.applePay 
              ? 'Apple Pay will be set up on your device'
              : 'Google Pay will be set up on your device',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).primaryColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'You can complete the setup after saving this payment method.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBankAccountFields() {
    return Column(
      children: [
        TextFormField(
          controller: _bankNameController,
          decoration: InputDecoration(
            labelText: 'Bank Name',
            hintText: 'e.g., Chase Bank',
            prefixIcon: const Icon(Icons.account_balance),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Theme.of(context).primaryColor),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          textCapitalization: TextCapitalization.words,
          validator: (value) {
            if (value == null || value.trim().length < 2) {
              return 'Please enter the bank name';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _accountNumberController,
          decoration: InputDecoration(
            labelText: 'Account Number',
            hintText: 'Last 4 digits only',
            prefixIcon: const Icon(Icons.numbers),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Theme.of(context).primaryColor),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(4),
          ],
          validator: (value) {
            if (value == null || value.length != 4) {
              return 'Enter last 4 digits of account';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildDefaultToggle() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SwitchListTile(
        title: const Text(
          'Set as Default',
          style: TextStyle(
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: const Text(
          'Use this payment method by default',
          style: TextStyle(
            color: Colors.grey,
          ),
        ),
        value: _isDefault,
        onChanged: (value) => setState(() => _isDefault = value),
        secondary: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _isDefault 
              ? Theme.of(context).primaryColor.withOpacity(0.1)
              : Colors.grey[100],
            shape: BoxShape.circle,
          ),
          child: Icon(
            _isDefault ? Icons.star : Icons.star_outline,
            color: _isDefault 
              ? Theme.of(context).primaryColor
              : Colors.grey,
          ),
        ),
        activeColor: Theme.of(context).primaryColor,
      ),
    );
  }

  String _getPaymentTypeLabel(PaymentMethodType type) {
    switch (type) {
      case PaymentMethodType.creditCard:
        return 'Credit Card';
      case PaymentMethodType.debitCard:
        return 'Debit Card';
      case PaymentMethodType.paypal:
        return 'PayPal';
      case PaymentMethodType.applePay:
        return 'Apple Pay';
      case PaymentMethodType.googlePay:
        return 'Google Pay';
      case PaymentMethodType.bankAccount:
        return 'Bank Account';
    }
  }

  IconData _getPaymentTypeIcon(PaymentMethodType type) {
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

  void _selectPaymentType(PaymentMethodType type) {
    setState(() {
      _selectedType = type;
      _clearTypeSpecificFields();
      _markAsChanged();
    });
  }

  void _clearTypeSpecificFields() {
    _cardNumberController.clear();
    _expiryController.clear();
    _holderNameController.clear();
    _emailController.clear();
    _bankNameController.clear();
    _accountNumberController.clear();
  }

  void _detectCardBrand(String cardNumber) {
    final digits = cardNumber.replaceAll(' ', '');
    if (digits.startsWith('4')) {
      _selectedCardBrand = 'visa';
    } else if (digits.startsWith('5') || digits.startsWith('2')) {
      _selectedCardBrand = 'mastercard';
    } else if (digits.startsWith('3')) {
      _selectedCardBrand = 'amex';
    } else if (digits.startsWith('6')) {
      _selectedCardBrand = 'discover';
    }
    setState(() {});
  }

  void _savePaymentMethod() {
    if (!_formKey.currentState!.validate()) return;

    final bloc = context.read<PaymentMethodBloc>();
    
    if (isEditing) {
      // Update existing payment method
      bloc.add(PaymentMethodUpdateEvent(
        id: widget.paymentMethodId!,
        label: _labelController.text.trim(),
        cardExpiryMonth: _getExpiryMonth(),
        cardExpiryYear: _getExpiryYear(),
        cardHolderName: _holderNameController.text.trim().isNotEmpty 
          ? _holderNameController.text.trim() : null,
        walletEmail: _emailController.text.trim().isNotEmpty 
          ? _emailController.text.trim() : null,
        bankName: _bankNameController.text.trim().isNotEmpty 
          ? _bankNameController.text.trim() : null,
        isDefault: _isDefault,
      ));
    } else {
      // Create new payment method
      bloc.add(PaymentMethodCreateEvent(
        type: _selectedType,
        label: _labelController.text.trim(),
        cardLast4: _getCardLast4(),
        cardBrand: _isCardType() ? _selectedCardBrand : null,
        cardExpiryMonth: _getExpiryMonth(),
        cardExpiryYear: _getExpiryYear(),
        cardHolderName: _holderNameController.text.trim().isNotEmpty 
          ? _holderNameController.text.trim() : null,
        walletEmail: _emailController.text.trim().isNotEmpty 
          ? _emailController.text.trim() : null,
        walletProvider: _getWalletProvider(),
        bankName: _bankNameController.text.trim().isNotEmpty 
          ? _bankNameController.text.trim() : null,
        bankAccountLast4: _accountNumberController.text.trim().isNotEmpty 
          ? _accountNumberController.text.trim() : null,
        isDefault: _isDefault,
      ));
    }
  }

  String? _getCardLast4() {
    if (!_isCardType()) return null;
    final digits = _cardNumberController.text.replaceAll(' ', '');
    return digits.length >= 4 ? digits.substring(digits.length - 4) : null;
  }

  int? _getExpiryMonth() {
    if (!_isCardType() || _expiryController.text.length != 5) return null;
    return int.tryParse(_expiryController.text.substring(0, 2));
  }

  int? _getExpiryYear() {
    if (!_isCardType() || _expiryController.text.length != 5) return null;
    final year = int.tryParse(_expiryController.text.substring(3, 5));
    return year != null ? 2000 + year : null;
  }

  String? _getWalletProvider() {
    switch (_selectedType) {
      case PaymentMethodType.paypal:
        return 'paypal';
      case PaymentMethodType.applePay:
        return 'apple_pay';
      case PaymentMethodType.googlePay:
        return 'google_pay';
      default:
        return null;
    }
  }

  bool _isCardType() {
    return _selectedType == PaymentMethodType.creditCard ||
           _selectedType == PaymentMethodType.debitCard;
  }

  void _showDiscardChangesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Discard Changes?',
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        content: const Text(
          'You have unsaved changes. Are you sure you want to discard them?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.pop();
            },
            child: const Text(
              'Discard',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Input formatters for better UX
class _CardNumberInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text.replaceAll(' ', '');
    final formatted = StringBuffer();
    
    for (int i = 0; i < text.length; i++) {
      if (i > 0 && i % 4 == 0) {
        formatted.write(' ');
      }
      formatted.write(text[i]);
    }
    
    return TextEditingValue(
      text: formatted.toString(),
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class _ExpiryDateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text.replaceAll('/', '');
    final formatted = StringBuffer();
    
    for (int i = 0; i < text.length && i < 4; i++) {
      if (i == 2) {
        formatted.write('/');
      }
      formatted.write(text[i]);
    }
    
    return TextEditingValue(
      text: formatted.toString(),
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
} 