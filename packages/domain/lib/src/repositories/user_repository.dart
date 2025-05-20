import 'package:dartz/dartz.dart';

import '../entities/user.dart';
import '../errors/failures.dart';

/// Repository for user operations
abstract class UserRepository {
  /// Get user profile
  Future<Either<Failure, User>> getUserProfile();
  
  /// Update user profile
  Future<Either<Failure, User>> updateUserProfile({
    String? name,
    String? phone,
    String? profilePicture,
  });
  
  /// Get user by ID (Admin only)
  Future<Either<Failure, User>> getUserById(String id);
  
  /// Get users by role (Admin only)
  Future<Either<Failure, List<User>>> getUsersByRole({
    required UserRole role,
    String? query,
    int page = 1,
    int limit = 20,
  });
  
  /// Create user (Admin only)
  Future<Either<Failure, User>> createUser({
    required String email,
    required String password,
    required String name,
    required UserRole role,
    String? phone,
  });
  
  /// Update user (Admin only)
  Future<Either<Failure, User>> updateUser({
    required String id,
    String? name,
    String? email,
    String? phone,
    UserRole? role,
    bool? isActive,
  });
  
  /// Delete user (Admin only)
  Future<Either<Failure, void>> deleteUser(String id);
  
  /// For Vendor: Get delivery personnel
  Future<Either<Failure, List<User>>> getDeliveryPersonnel({
    bool? isActive,
    int page = 1,
    int limit = 20,
  });
}