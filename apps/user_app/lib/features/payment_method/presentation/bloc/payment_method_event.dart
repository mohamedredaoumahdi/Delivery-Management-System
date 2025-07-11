import 'package:equatable/equatable.dart';
import 'package:domain/domain.dart';

abstract class PaymentMethodEvent extends Equatable {
  const PaymentMethodEvent();

  @override
  List<Object?> get props => [];
}

/// Event to load all payment methods
class PaymentMethodLoadEvent extends PaymentMethodEvent {
  const PaymentMethodLoadEvent();
}

/// Event to create a new payment method
class PaymentMethodCreateEvent extends PaymentMethodEvent {
  final PaymentMethodType type;
  final String label;
  final String? cardLast4;
  final String? cardBrand;
  final int? cardExpiryMonth;
  final int? cardExpiryYear;
  final String? cardHolderName;
  final String? walletEmail;
  final String? walletProvider;
  final String? bankName;
  final String? bankAccountLast4;
  final bool isDefault;

  const PaymentMethodCreateEvent({
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
    this.isDefault = false,
  });

  @override
  List<Object?> get props => [
    type, label, cardLast4, cardBrand, cardExpiryMonth, cardExpiryYear,
    cardHolderName, walletEmail, walletProvider, bankName, bankAccountLast4, isDefault,
  ];
}

/// Event to update an existing payment method
class PaymentMethodUpdateEvent extends PaymentMethodEvent {
  final String id;
  final String? label;
  final int? cardExpiryMonth;
  final int? cardExpiryYear;
  final String? cardHolderName;
  final String? walletEmail;
  final String? bankName;
  final bool? isDefault;

  const PaymentMethodUpdateEvent({
    required this.id,
    this.label,
    this.cardExpiryMonth,
    this.cardExpiryYear,
    this.cardHolderName,
    this.walletEmail,
    this.bankName,
    this.isDefault,
  });

  @override
  List<Object?> get props => [
    id, label, cardExpiryMonth, cardExpiryYear, cardHolderName, walletEmail, bankName, isDefault,
  ];
}

/// Event to delete a payment method
class PaymentMethodDeleteEvent extends PaymentMethodEvent {
  final String id;

  const PaymentMethodDeleteEvent({required this.id});

  @override
  List<Object?> get props => [id];
}

/// Event to set a payment method as default
class PaymentMethodSetDefaultEvent extends PaymentMethodEvent {
  final String id;

  const PaymentMethodSetDefaultEvent({required this.id});

  @override
  List<Object?> get props => [id];
}

/// Event to refresh the payment methods list
class PaymentMethodRefreshEvent extends PaymentMethodEvent {
  const PaymentMethodRefreshEvent();
}