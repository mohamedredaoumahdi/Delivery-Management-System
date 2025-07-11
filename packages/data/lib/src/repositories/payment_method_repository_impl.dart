import 'package:core/core.dart' hide ApiClient;
import 'package:dartz/dartz.dart';
import 'package:domain/domain.dart';
import 'package:dio/dio.dart';
import '../api/api_client.dart';

class PaymentMethodRepositoryImpl implements PaymentMethodRepository {
  final ApiClient apiClient;
  final LoggerService logger;

  PaymentMethodRepositoryImpl({
    required this.apiClient,
    required this.logger,
  });

  @override
  Future<Either<Failure, List<UserPaymentMethod>>> getPaymentMethods() async {
    try {
      logger.i('💳 PaymentMethodRepositoryImpl: Getting user payment methods');
      
      final response = await apiClient.get('/users/payment-methods');
      
      final List<dynamic> data = response.data['data'];
      final paymentMethods = data.map((json) => UserPaymentMethod.fromJson(json)).toList();
      
      logger.i('💳 ✅ PaymentMethodRepositoryImpl: Successfully fetched ${paymentMethods.length} payment methods');
      return Right(paymentMethods);
    } on DioException catch (e) {
      logger.e('💳 ❌ PaymentMethodRepositoryImpl: Error fetching payment methods', e);
      return Left(ServerFailure(e.message ?? 'Failed to fetch payment methods'));
    } catch (e) {
      logger.e('💳 ❌ PaymentMethodRepositoryImpl: Unexpected error', e);
      return Left(ServerFailure('Unexpected error occurred'));
    }
  }

  @override
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
  }) async {
    try {
      logger.i('💳 PaymentMethodRepositoryImpl: Creating payment method');
      
      final data = {
        'type': type.toString().split('.').last.toUpperCase(),
        'label': label,
        'isDefault': isDefault,
      };

      // Add type-specific fields
      if (cardLast4 != null) data['cardLast4'] = cardLast4;
      if (cardBrand != null) data['cardBrand'] = cardBrand;
      if (cardExpiryMonth != null) data['cardExpiryMonth'] = cardExpiryMonth;
      if (cardExpiryYear != null) data['cardExpiryYear'] = cardExpiryYear;
      if (cardHolderName != null) data['cardHolderName'] = cardHolderName;
      if (walletEmail != null) data['walletEmail'] = walletEmail;
      if (walletProvider != null) data['walletProvider'] = walletProvider;
      if (bankName != null) data['bankName'] = bankName;
      if (bankAccountLast4 != null) data['bankAccountLast4'] = bankAccountLast4;

      final response = await apiClient.post('/users/payment-methods', data: data);
      final paymentMethod = UserPaymentMethod.fromJson(response.data['data']);
      
      logger.i('💳 ✅ PaymentMethodRepositoryImpl: Successfully created payment method');
      return Right(paymentMethod);
    } on DioException catch (e) {
      logger.e('💳 ❌ PaymentMethodRepositoryImpl: Error creating payment method', e);
      return Left(ServerFailure(e.message ?? 'Failed to create payment method'));
    } catch (e) {
      logger.e('💳 ❌ PaymentMethodRepositoryImpl: Unexpected error', e);
      return Left(ServerFailure('Unexpected error occurred'));
    }
  }

  @override
  Future<Either<Failure, UserPaymentMethod>> updatePaymentMethod({
    required String id,
    String? label,
    int? cardExpiryMonth,
    int? cardExpiryYear,
    String? cardHolderName,
    String? walletEmail,
    String? bankName,
    bool? isDefault,
  }) async {
    try {
      logger.i('💳 PaymentMethodRepositoryImpl: Updating payment method $id');
      
      final data = <String, dynamic>{};
      
      if (label != null) data['label'] = label;
      if (cardExpiryMonth != null) data['cardExpiryMonth'] = cardExpiryMonth;
      if (cardExpiryYear != null) data['cardExpiryYear'] = cardExpiryYear;
      if (cardHolderName != null) data['cardHolderName'] = cardHolderName;
      if (walletEmail != null) data['walletEmail'] = walletEmail;
      if (bankName != null) data['bankName'] = bankName;
      if (isDefault != null) data['isDefault'] = isDefault;

      final response = await apiClient.put('/users/payment-methods/$id', data: data);
      final paymentMethod = UserPaymentMethod.fromJson(response.data['data']);
      
      logger.i('💳 ✅ PaymentMethodRepositoryImpl: Successfully updated payment method');
      return Right(paymentMethod);
    } on DioException catch (e) {
      logger.e('💳 ❌ PaymentMethodRepositoryImpl: Error updating payment method', e);
      return Left(ServerFailure(e.message ?? 'Failed to update payment method'));
    } catch (e) {
      logger.e('💳 ❌ PaymentMethodRepositoryImpl: Unexpected error', e);
      return Left(ServerFailure('Unexpected error occurred'));
    }
  }

  @override
  Future<Either<Failure, void>> deletePaymentMethod(String id) async {
    try {
      logger.i('💳 PaymentMethodRepositoryImpl: Deleting payment method $id');
      
      await apiClient.delete('/users/payment-methods/$id');
      
      logger.i('💳 ✅ PaymentMethodRepositoryImpl: Successfully deleted payment method');
      return const Right(null);
    } on DioException catch (e) {
      logger.e('💳 ❌ PaymentMethodRepositoryImpl: Error deleting payment method', e);
      return Left(ServerFailure(e.message ?? 'Failed to delete payment method'));
    } catch (e) {
      logger.e('💳 ❌ PaymentMethodRepositoryImpl: Unexpected error', e);
      return Left(ServerFailure('Unexpected error occurred'));
    }
  }

  @override
  Future<Either<Failure, UserPaymentMethod>> setDefaultPaymentMethod(String id) async {
    try {
      logger.i('💳 PaymentMethodRepositoryImpl: Setting default payment method $id');
      
      final response = await apiClient.put('/users/payment-methods/$id/default');
      final paymentMethod = UserPaymentMethod.fromJson(response.data['data']);
      
      logger.i('💳 ✅ PaymentMethodRepositoryImpl: Successfully set default payment method');
      return Right(paymentMethod);
    } on DioException catch (e) {
      logger.e('💳 ❌ PaymentMethodRepositoryImpl: Error setting default payment method', e);
      return Left(ServerFailure(e.message ?? 'Failed to set default payment method'));
    } catch (e) {
      logger.e('💳 ❌ PaymentMethodRepositoryImpl: Unexpected error', e);
      return Left(ServerFailure('Unexpected error occurred'));
    }
  }
} 