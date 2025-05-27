import 'package:dartz/dartz.dart';
import 'package:domain/domain.dart';

abstract class UserRepository {
  Future<Either<Failure, User?>> getCurrentUser();
  Future<Either<Failure, User>> signInWithEmailAndPassword({required String email, required String password});
  Future<Either<Failure, User>> signUpWithEmailAndPassword({required String email, required String password, required String name, required UserRole role, String? phone});
  Future<Either<Failure, void>> signOut();
  Future<Either<Failure, void>> sendPasswordResetEmail({required String email});
  Future<Either<Failure, User>> getProfile();
  Future<Either<Failure, User>> updateProfile(Map<String, dynamic> data);
  Future<Either<Failure, void>> changePassword(String currentPassword, String newPassword);
} 