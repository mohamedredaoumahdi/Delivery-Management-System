import 'package:dartz/dartz.dart' as dartz;

import '../entities/user.dart';
import '../entities/shop.dart';
import '../errors/failures.dart';

/// Repository for user operations
abstract class UserRepository {
  /// Get user profile
  Future<dartz.Either<Failure, User>> getUserProfile();
  
  /// Update user profile
  Future<dartz.Either<Failure, User>> updateUserProfile({
    String? name,
    String? phone,
    String? profilePicture,
  });
  
  /// Get user by ID (Admin only)
  Future<dartz.Either<Failure, User>> getUserById(String id);
  
  /// Get users by role (Admin only)
  Future<dartz.Either<Failure, List<User>>> getUsersByRole({
    required UserRole role,
    String? query,
    int page = 1,
    int limit = 20,
  });
  
  /// Create user (Admin only)
  Future<dartz.Either<Failure, User>> createUser({
    required String email,
    required String password,
    required String name,
    required UserRole role,
    String? phone,
  });
  
  /// Update user (Admin only)
  Future<dartz.Either<Failure, User>> updateUser({
    required String id,
    String? name,
    String? email,
    String? phone,
    UserRole? role,
    bool? isActive,
  });
  
  /// Delete user (Admin only)
  Future<dartz.Either<Failure, void>> deleteUser(String id);
  
  /// For Vendor: Get delivery personnel
  Future<dartz.Either<Failure, List<User>>> getDeliveryPersonnel({
    bool? isActive,
    int page = 1,
    int limit = 20,
  });
  
  /// Get current user
  Future<dartz.Either<Failure, User>> getCurrentUser();
  
  /// Change password
  Future<dartz.Either<Failure, void>> changePassword({
    required String currentPassword,
    required String newPassword,
  });
  
  /// Upload profile picture
  Future<dartz.Either<Failure, String>> uploadProfilePicture(String imagePath);
  
  /// Add shop to favorites
  Future<dartz.Either<Failure, void>> addToFavorites(String shopId);
  
  /// Remove shop from favorites
  Future<dartz.Either<Failure, void>> removeFromFavorites(String shopId);
  
  /// Get user's favorite shops
  Future<dartz.Either<Failure, List<Shop>>> getFavoriteShops();
  
  /// Check if shop is in favorites
  Future<dartz.Either<Failure, bool>> isShopFavorite(String shopId);
}