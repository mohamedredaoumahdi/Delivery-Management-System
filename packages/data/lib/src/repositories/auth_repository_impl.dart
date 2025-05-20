import 'dart:async';

import 'package:core/core.dart';
import 'package:dartz/dartz.dart';
import 'package:domain/domain.dart';

import '../datasources/local/auth_local_data_source.dart';
import '../datasources/remote/auth_remote_data_source.dart';
import '../models/user_model.dart';

/// Implementation of the [AuthRepository]
class AuthRepositoryImpl implements AuthRepository {
  /// Remote data source for authentication
  final AuthRemoteDataSource remoteDataSource;
  
  /// Local data source for authentication
  final AuthLocalDataSource localDataSource;
  
  /// Logger service
  final LoggerService logger;
  
  /// Current authenticated user
  User? _currentUser;
  
  /// Stream controller for auth state changes
  final StreamController<User?> _authStateController = 
      StreamController<User?>.broadcast();
  
  /// Stream of auth state changes
  Stream<User?> get authStateChanges => _authStateController.stream;

  /// Creates an auth repository
  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.logger,
  }) {
    // Check if user is already authenticated
    _init();
  }
  
  /// Initialize repository
  Future<void> _init() async {
    try {
      final token = await localDataSource.getAuthToken();
      
      if (token != null) {
        final userModel = await remoteDataSource.getCurrentUser();
        _currentUser = userModel.toDomain();
        _authStateController.add(_currentUser);
      }
    } catch (e) {
      logger.e('Error initializing auth repository', e);
      // Clear token if it's invalid
      await localDataSource.clearAuthToken();
      _currentUser = null;
      _authStateController.add(null);
    }
  }

  @override
  Future<Either<Failure, User>> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final response = await remoteDataSource.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Save auth token
      await localDataSource.saveAuthToken(response.token);
      
      // Save user
      _currentUser = response.user.toDomain();
      _authStateController.add(_currentUser);
      
      return Right(_currentUser!);
    } catch (e) {
      logger.e('Sign in error', e);
      return Left(_handleError(e));
    }
  }

  @override
  Future<Either<Failure, User>> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    required UserRole role,
    String? phone,
  }) async {
    try {
      final response = await remoteDataSource.signUpWithEmailAndPassword(
        email: email,
        password: password,
        name: name,
        role: UserModel._mapUserRoleToString(role),
        phone: phone,
      );
      
      // Save auth token
      await localDataSource.saveAuthToken(response.token);
      
      // Save user
      _currentUser = response.user.toDomain();
      _authStateController.add(_currentUser);
      
      return Right(_currentUser!);
    } catch (e) {
      logger.e('Sign up error', e);
      return Left(_handleError(e));
    }
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      await remoteDataSource.signOut();
      
      // Clear auth token
      await localDataSource.clearAuthToken();
      
      // Clear user
      _currentUser = null;
      _authStateController.add(null);
      
      return const Right(null);
    } catch (e) {
      logger.e('Sign out error', e);
      return Left(_handleError(e));
    }
  }

  @override
  Future<Either<Failure, User?>> getCurrentUser() async {
    if (_currentUser != null) {
      return Right(_currentUser);
    }
    
    try {
      final token = await localDataSource.getAuthToken();
      
      if (token == null) {
        return const Right(null);
      }
      
      final userModel = await remoteDataSource.getCurrentUser();
      _currentUser = userModel.toDomain();
      _authStateController.add(_currentUser);
      
      return Right(_currentUser);
    } catch (e) {
      logger.e('Get current user error', e);
      
      // Clear token if it's invalid
      await localDataSource.clearAuthToken();
      _currentUser = null;
      _authStateController.add(null);
      
      return Left(_handleError(e));
    }
  }

  @override
  Future<Either<Failure, void>> sendPasswordResetEmail({
    required String email,
  }) async {
    try {
      await remoteDataSource.sendPasswordResetEmail(email: email);
      return const Right(null);
    } catch (e) {
      logger.e('Send password reset email error', e);
      return Left(_handleError(e));
    }
  }

  @override
  Future<Either<Failure, User>> updateProfile({
    required String name,
    String? phone,
    String? profilePicture,
  }) async {
    try {
      final userModel = await remoteDataSource.updateProfile(
        name: name,
        phone: phone,
        profilePicture: profilePicture,
      );
      
      _currentUser = userModel.toDomain();
      _authStateController.add(_currentUser);
      
      return Right(_currentUser!);
    } catch (e) {
      logger.e('Update profile error', e);
      return Left(_handleError(e));
    }
  }

  @override
  Future<Either<Failure, void>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await remoteDataSource.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      
      return const Right(null);
    } catch (e) {
      logger.e('Change password error', e);
      return Left(_handleError(e));
    }
  }

  @override
  Future<Either<Failure, void>> deleteAccount({
    required String password,
  }) async {
    try {
      await remoteDataSource.deleteAccount(password: password);
      
      // Clear auth token
      await localDataSource.clearAuthToken();
      
      // Clear user
      _currentUser = null;
      _authStateController.add(null);
      
      return const Right(null);
    } catch (e) {
      logger.e('Delete account error', e);
      return Left(_handleError(e));
    }
  }
  
  /// Handle error and convert to Failure
  Failure _handleError(dynamic error) {
    if (error is UnauthorizedException) {
      return const AuthFailure('Authentication failed. Please sign in again.');
    } else if (error is NetworkException) {
      return const NetworkFailure('No internet connection. Please try again.');
    } else if (error is TimeoutException) {
      return const TimeoutFailure('Request timed out. Please try again.');
    } else if (error is ValidationException) {
      return const ValidationFailure('email', 'Invalid email or password.');
    } else if (error is ServerException) {
      return ServerFailure(
        error.message,
        statusCode: error.statusCode,
      );
    } else {
      return UnknownFailure(error.toString());
    }
  }
  
  /// Dispose repository
  void dispose() {
    _authStateController.close();
  }
}