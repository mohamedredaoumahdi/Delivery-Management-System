import 'package:dartz/dartz.dart';

import '../entities/address.dart';
import '../errors/failures.dart';

abstract class AddressRepository {
  Future<Either<Failure, List<Address>>> getAddresses();
  Future<Either<Failure, Address>> createAddress({
    required String label,
    required String fullAddress,
    required double latitude,
    required double longitude,
    String? instructions,
    required bool isDefault,
  });
  Future<Either<Failure, Address>> updateAddress({
    required String id,
    required String label,
    required String fullAddress,
    required double latitude,
    required double longitude,
    String? instructions,
    required bool isDefault,
  });
  Future<Either<Failure, void>> deleteAddress(String id);
  Future<Either<Failure, Address>> setDefaultAddress(String id);
} 