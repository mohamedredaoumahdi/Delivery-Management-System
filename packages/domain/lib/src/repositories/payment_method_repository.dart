import 'package:dartz/dartz.dart';

import '../entities/payment_method.dart';
import '../errors/failures.dart';

/// Repository for payment method operations
abstract class PaymentMethodRepository {
  /// Get all payment methods for the authenticated user
  Future<Either<Failure, List<UserPaymentMethod>>> getPaymentMethods();
  
  /// Create a new payment method
  Future<Either<Failure, UserPaymentMethod>> createPaymentMethod({
    required PaymentMethodType type,
    required String label,
    String? cardLast4,
    String? cardBrand,
    int? cardExpiryMonth,
    int? cardExpiryYear,
    String? cardHolderName,
    String? walletEmail,
    String? walletProvider,
    String? bankName,
    String? bankAccountLast4,
    bool isDefault = false,
  });
  
  /// Update an existing payment method
  Future<Either<Failure, UserPaymentMethod>> updatePaymentMethod({
    required String id,
    String? label,
    int? cardExpiryMonth,
    int? cardExpiryYear,
    String? cardHolderName,
    String? walletEmail,
    String? bankName,
    bool? isDefault,
  });
  
  /// Delete a payment method
  Future<Either<Failure, void>> deletePaymentMethod(String id);
  
  /// Set a payment method as default
  Future<Either<Failure, UserPaymentMethod>> setDefaultPaymentMethod(String id);
} 