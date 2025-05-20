import 'package:dartz/dartz.dart';

import '../entities/user.dart';
import '../errors/failures.dart';

/// Repository for authentication operations
abstract class AuthRepository {
  /// Sign in with email and password
  Future<Either<Failure, User>> signInWithEmailAndPassword({
    required String email,
    required String password,
  });
  
  /// Sign up with email and password
  Future<Either<Failure, User>> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    required UserRole role,
    String? phone,
  });
  
  /// Sign out the current user
  Future<Either<Failure, void>> signOut();
  
  /// Get the current authenticated user
  Future<Either<Failure, User?>> getCurrentUser();
  
  /// Send password reset email
  Future<Either<Failure, void>> sendPasswordResetEmail({
    required String email,
  });
  
  /// Update user profile
  Future<Either<Failure, User>> updateProfile({
    required String name,
    String? phone,
    String? profilePicture,
  });
  
  /// Change password
  Future<Either<Failure, void>> changePassword({
    required String currentPassword,
    required String newPassword,
  });
  
  /// Delete account
  Future<Either<Failure, void>> deleteAccount({
    required String password,
  });
}