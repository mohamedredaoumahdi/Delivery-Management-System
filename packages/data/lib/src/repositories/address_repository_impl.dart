import 'package:core/core.dart' hide ApiClient;
import 'package:dartz/dartz.dart';
import 'package:domain/domain.dart';

import '../api/api_client.dart';

class AddressRepositoryImpl implements AddressRepository {
  final ApiClient apiClient;
  final LoggerService logger;

  AddressRepositoryImpl({
    required this.apiClient,
    required this.logger,
  });

  @override
  Future<Either<Failure, List<Address>>> getAddresses() async {
    try {
      logger.i('🏠 AddressRepositoryImpl: Getting user addresses');
      
      final response = await apiClient.get('/users/addresses');
      
      logger.d('📦 AddressRepositoryImpl: Response data: ${response.data}');
      
      final addressesJson = response.data['data'] as List;
      final addresses = addressesJson
          .map((json) => Address.fromJson(json as Map<String, dynamic>))
          .toList();
      
      logger.i('✅ AddressRepositoryImpl: Successfully fetched ${addresses.length} addresses');
      return Right(addresses);
    } catch (e) {
      logger.e('❌ AddressRepositoryImpl: Error getting addresses', e);
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Address>> createAddress({
    required String label,
    required String fullAddress,
    required double latitude,
    required double longitude,
    String? instructions,
    required bool isDefault,
  }) async {
    try {
      logger.i('🏠 AddressRepositoryImpl: Creating new address with label: $label');
      
      final response = await apiClient.post('/users/addresses', data: {
        'label': label,
        'fullAddress': fullAddress,
        'latitude': latitude,
        'longitude': longitude,
        'instructions': instructions,
        'isDefault': isDefault,
      });
      
      logger.d('📦 AddressRepositoryImpl: Create response: ${response.data}');
      
      final addressJson = response.data['data'] as Map<String, dynamic>;
      final address = Address.fromJson(addressJson);
      
      logger.i('✅ AddressRepositoryImpl: Successfully created address: ${address.id}');
      return Right(address);
    } catch (e) {
      logger.e('❌ AddressRepositoryImpl: Error creating address', e);
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Address>> updateAddress({
    required String id,
    required String label,
    required String fullAddress,
    required double latitude,
    required double longitude,
    String? instructions,
    required bool isDefault,
  }) async {
    try {
      logger.i('🏠 AddressRepositoryImpl: Updating address: $id');
      
      final response = await apiClient.put('/users/addresses/$id', data: {
        'label': label,
        'fullAddress': fullAddress,
        'latitude': latitude,
        'longitude': longitude,
        'instructions': instructions,
        'isDefault': isDefault,
      });
      
      logger.d('📦 AddressRepositoryImpl: Update response: ${response.data}');
      
      final addressJson = response.data['data'] as Map<String, dynamic>;
      final address = Address.fromJson(addressJson);
      
      logger.i('✅ AddressRepositoryImpl: Successfully updated address: ${address.id}');
      return Right(address);
    } catch (e) {
      logger.e('❌ AddressRepositoryImpl: Error updating address', e);
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteAddress(String id) async {
    try {
      logger.i('🏠 AddressRepositoryImpl: Deleting address: $id');
      
      await apiClient.delete('/users/addresses/$id');
      
      logger.i('✅ AddressRepositoryImpl: Successfully deleted address: $id');
      return const Right(null);
    } catch (e) {
      logger.e('❌ AddressRepositoryImpl: Error deleting address', e);
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Address>> setDefaultAddress(String id) async {
    try {
      logger.i('🏠 AddressRepositoryImpl: Setting default address: $id');
      
      final response = await apiClient.patch('/users/addresses/$id/default');
      
      logger.d('📦 AddressRepositoryImpl: Set default response: ${response.data}');
      
      final addressJson = response.data['data'] as Map<String, dynamic>;
      final address = Address.fromJson(addressJson);
      
      logger.i('✅ AddressRepositoryImpl: Successfully set default address: ${address.id}');
      return Right(address);
    } catch (e) {
      logger.e('❌ AddressRepositoryImpl: Error setting default address', e);
      return Left(ServerFailure(e.toString()));
    }
  }
} 