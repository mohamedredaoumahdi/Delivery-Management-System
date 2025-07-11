import 'package:equatable/equatable.dart';

/// Payment method type enum for saved payment methods
enum PaymentMethodType {
  /// Credit card
  creditCard,
  
  /// Debit card
  debitCard,
  
  /// PayPal account
  paypal,
  
  /// Apple Pay
  applePay,
  
  /// Google Pay
  googlePay,
  
  /// Bank account
  bankAccount,
}

/// User payment method entity representing a saved payment method
class UserPaymentMethod extends Equatable {
  /// Unique identifier for the payment method
  final String id;
  
  /// Type of payment method
  final PaymentMethodType type;
  
  /// User-friendly label for the payment method
  final String label;
  
  /// Last 4 digits of card (for cards)
  final String? cardLast4;
  
  /// Card brand (visa, mastercard, amex, etc.)
  final String? cardBrand;
  
  /// Card expiry month (1-12)
  final int? cardExpiryMonth;
  
  /// Card expiry year
  final int? cardExpiryYear;
  
  /// Cardholder name
  final String? cardHolderName;
  
  /// Wallet email (for PayPal, etc.)
  final String? walletEmail;
  
  /// Wallet provider (paypal, apple_pay, google_pay)
  final String? walletProvider;
  
  /// Bank name (for bank accounts)
  final String? bankName;
  
  /// Last 4 digits of bank account
  final String? bankAccountLast4;
  
  /// Whether this is the default payment method
  final bool isDefault;
  
  /// Whether this payment method is active
  final bool isActive;
  
  /// User ID who owns this payment method
  final String userId;
  
  /// Date when the payment method was created
  final DateTime createdAt;
  
  /// Date when the payment method was last updated
  final DateTime updatedAt;

  /// Creates a payment method entity
  const UserPaymentMethod({
    required this.id,
    required this.type,
    required this.label,
    this.cardLast4,
    this.cardBrand,
    this.cardExpiryMonth,
    this.cardExpiryYear,
    this.cardHolderName,
    this.walletEmail,
    this.walletProvider,
    this.bankName,
    this.bankAccountLast4,
    required this.isDefault,
    required this.isActive,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Creates a copy of this payment method with the given fields replaced
  UserPaymentMethod copyWith({
    String? id,
    PaymentMethodType? type,
    String? label,
    String? cardLast4,
    String? cardBrand,
    int? cardExpiryMonth,
    int? cardExpiryYear,
    String? cardHolderName,
    String? walletEmail,
    String? walletProvider,
    String? bankName,
    String? bankAccountLast4,
    bool? isDefault,
    bool? isActive,
    String? userId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserPaymentMethod(
      id: id ?? this.id,
      type: type ?? this.type,
      label: label ?? this.label,
      cardLast4: cardLast4 ?? this.cardLast4,
      cardBrand: cardBrand ?? this.cardBrand,
      cardExpiryMonth: cardExpiryMonth ?? this.cardExpiryMonth,
      cardExpiryYear: cardExpiryYear ?? this.cardExpiryYear,
      cardHolderName: cardHolderName ?? this.cardHolderName,
      walletEmail: walletEmail ?? this.walletEmail,
      walletProvider: walletProvider ?? this.walletProvider,
      bankName: bankName ?? this.bankName,
      bankAccountLast4: bankAccountLast4 ?? this.bankAccountLast4,
      isDefault: isDefault ?? this.isDefault,
      isActive: isActive ?? this.isActive,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Creates a payment method from JSON
  factory UserPaymentMethod.fromJson(Map<String, dynamic> json) {
    return UserPaymentMethod(
      id: json['id'] as String,
      type: _parsePaymentMethodType(json['type'] as String),
      label: json['label'] as String,
      cardLast4: json['cardLast4'] as String?,
      cardBrand: json['cardBrand'] as String?,
      cardExpiryMonth: json['cardExpiryMonth'] as int?,
      cardExpiryYear: json['cardExpiryYear'] as int?,
      cardHolderName: json['cardHolderName'] as String?,
      walletEmail: json['walletEmail'] as String?,
      walletProvider: json['walletProvider'] as String?,
      bankName: json['bankName'] as String?,
      bankAccountLast4: json['bankAccountLast4'] as String?,
      isDefault: json['isDefault'] as bool,
      isActive: json['isActive'] as bool,
      userId: json['userId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// Parse payment method type from string
  static PaymentMethodType _parsePaymentMethodType(String typeString) {
    switch (typeString.toUpperCase()) {
      case 'CREDIT_CARD':
        return PaymentMethodType.creditCard;
      case 'DEBIT_CARD':
        return PaymentMethodType.debitCard;
      case 'PAYPAL':
        return PaymentMethodType.paypal;
      case 'APPLE_PAY':
        return PaymentMethodType.applePay;
      case 'GOOGLE_PAY':
        return PaymentMethodType.googlePay;
      case 'BANK_ACCOUNT':
        return PaymentMethodType.bankAccount;
      default:
        return PaymentMethodType.creditCard;
    }
  }

  /// Converts the payment method to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString().split('.').last.toUpperCase(),
      'label': label,
      'cardLast4': cardLast4,
      'cardBrand': cardBrand,
      'cardExpiryMonth': cardExpiryMonth,
      'cardExpiryYear': cardExpiryYear,
      'cardHolderName': cardHolderName,
      'walletEmail': walletEmail,
      'walletProvider': walletProvider,
      'bankName': bankName,
      'bankAccountLast4': bankAccountLast4,
      'isDefault': isDefault,
      'isActive': isActive,
      'userId': userId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Get display name for the payment method
  String get displayName {
    switch (type) {
      case PaymentMethodType.creditCard:
      case PaymentMethodType.debitCard:
        return '$cardBrand •••• $cardLast4';
      case PaymentMethodType.paypal:
        return 'PayPal ($walletEmail)';
      case PaymentMethodType.applePay:
        return 'Apple Pay';
      case PaymentMethodType.googlePay:
        return 'Google Pay';
      case PaymentMethodType.bankAccount:
        return '$bankName •••• $bankAccountLast4';
      default:
        return label;
    }
  }

  /// Get icon name for the payment method
  String get iconName {
    switch (type) {
      case PaymentMethodType.creditCard:
      case PaymentMethodType.debitCard:
        return 'credit_card';
      case PaymentMethodType.paypal:
        return 'paypal';
      case PaymentMethodType.applePay:
        return 'apple_pay';
      case PaymentMethodType.googlePay:
        return 'google_pay';
      case PaymentMethodType.bankAccount:
        return 'account_balance';
      default:
        return 'payment';
    }
  }

  /// Check if the payment method is expired (for cards)
  bool get isExpired {
    if (cardExpiryMonth == null || cardExpiryYear == null) return false;
    
    final now = DateTime.now();
    final expiryDate = DateTime(cardExpiryYear!, cardExpiryMonth! + 1, 0);
    return now.isAfter(expiryDate);
  }

  /// Check if the payment method is expiring soon (within 3 months)
  bool get isExpiringSoon {
    if (cardExpiryMonth == null || cardExpiryYear == null) return false;
    
    final now = DateTime.now();
    final expiryDate = DateTime(cardExpiryYear!, cardExpiryMonth! + 1, 0);
    final threeMonthsFromNow = now.add(const Duration(days: 90));
    return now.isBefore(expiryDate) && threeMonthsFromNow.isAfter(expiryDate);
  }

  @override
  List<Object?> get props => [
    id, type, label, cardLast4, cardBrand, cardExpiryMonth, cardExpiryYear,
    cardHolderName, walletEmail, walletProvider, bankName, bankAccountLast4,
    isDefault, isActive, userId, createdAt, updatedAt,
  ];
} 