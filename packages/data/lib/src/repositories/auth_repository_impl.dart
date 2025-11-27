import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:domain/domain.dart';
import 'package:core/core.dart' show 
  LoggerService, 
  NetworkException, 
  TimeoutException, 
  ServerFailure,
  NetworkFailure,
  TimeoutFailure,
  UnknownFailure,
  AuthFailure,
  ValidationFailure;
import 'package:core/src/exceptions/api_exceptions.dart' show ApiException;

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
  /// Note: This method does NOT validate the token immediately to avoid
  /// clearing valid tokens during app initialization/hot restart.
  /// Token validation is handled by AuthBloc via AuthCheckStatusEvent.
  Future<void> _init() async {
    try {
      final token = await localDataSource.getAuthToken();
      
      if (token != null) {
        // Token exists, but don't validate it immediately
        // Let the AuthBloc handle validation via AuthCheckStatusEvent
        // This prevents clearing valid tokens during hot restart
        logger.d('Auth token found during initialization, validation will be handled by AuthBloc');
        _currentUser = null; // Will be set when AuthBloc validates
        _authStateController.add(null);
      } else {
        _currentUser = null;
        _authStateController.add(null);
      }
    } catch (e) {
      logger.e('Error initializing auth repository', e);
      // Don't clear token on initialization errors - let normal flow handle it
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
      
      // Store both tokens
      await localDataSource.saveAuthToken(response.data.accessToken);
      await localDataSource.saveRefreshToken(response.data.refreshToken);
      
      _currentUser = response.data.user.toDomain();
      _authStateController.add(_currentUser);
      
      return Right(response.data.user.toDomain());
    } catch (e) {
      logger.e('Error signing in with email and password', e);
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
    required String confirmPassword,
  }) async {
    try {
      final response = await remoteDataSource.signUpWithEmailAndPassword(
        email: email,
        password: password,
        name: name,
        role: UserModel.mapUserRoleToString(role),
        phone: phone,
        confirmPassword: confirmPassword,
      );
      
      // Store both tokens
      await localDataSource.saveAuthToken(response.data.accessToken);
      await localDataSource.saveRefreshToken(response.data.refreshToken);
      
      _currentUser = response.data.user.toDomain();
      _authStateController.add(_currentUser);
      
      return Right(response.data.user.toDomain());
    } catch (e) {
      logger.e('Error signing up with email and password', e);
      return Left(_handleError(e));
    }
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      await remoteDataSource.signOut();
      await localDataSource.clearAllAuthData();
      _currentUser = null;
      _authStateController.add(null);
      return const Right(null);
    } catch (e) {
      logger.e('Error signing out', e);
      return Left(_handleError(e));
    }
  }

  @override
  Future<Either<Failure, User?>> getCurrentUser() async {
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
      logger.e('Error getting current user', e);
      
      // Only clear token if it's a 401 (unauthorized) error
      // Don't clear on network errors or other issues
      if (e is ApiException && e.statusCode == 401) {
        await localDataSource.clearAuthToken();
        _currentUser = null;
        _authStateController.add(null);
      } else {
        // For other errors, keep the token and just return null user
        // The token might still be valid, just couldn't verify right now
        _currentUser = null;
        _authStateController.add(null);
      }
      
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
      logger.e('Error sending password reset email', e);
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
      final user = await remoteDataSource.updateProfile(
        name: name,
        phone: phone,
        profilePicture: profilePicture,
      );
      return Right(user.toDomain());
    } catch (e) {
      logger.e('Error updating profile', e);
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
      logger.e('Error changing password', e);
      return Left(_handleError(e));
    }
  }

  @override
  Future<Either<Failure, void>> deleteAccount({
    required String password,
  }) async {
    try {
      await remoteDataSource.deleteAccount(password: password);
      await localDataSource.clearAuthToken();
      return const Right(null);
    } catch (e) {
      logger.e('Error deleting account', e);
      return Left(_handleError(e));
    }
  }
  
  /// Handle error and convert to Failure
  Failure _handleError(dynamic error) {
    if (error is ApiException) {
      if (error.statusCode == 401) {
        return AuthFailure(error.message ?? 'Incorrect password. Please check your password and try again.');
      } else if (error.statusCode == 404) {
        return AuthFailure(error.message ?? 'No account found with this email address. Please check your email or sign up for a new account.');
      } else if (error.statusCode == 403) {
        return AuthFailure(error.message ?? 'Your account has been deactivated. Please contact support for assistance.');
      } else if (error.statusCode == 400) {
        return ValidationFailure('auth', error.message ?? 'Invalid request');
      } else if (error.statusCode != null && error.statusCode! >= 500) {
        return ServerFailure(
          error.message ?? 'Server error occurred',
          statusCode: error.statusCode,
        );
      }
    } else if (error.toString().contains('AuthException')) {
      // Handle AuthException from core package
      final errorMessage = error.toString();
      if (errorMessage.contains('ACCOUNT_NOT_FOUND')) {
        return AuthFailure('No account found with this email address. Please check your email or sign up for a new account.');
      } else if (errorMessage.contains('INCORRECT_PASSWORD')) {
        return AuthFailure('Incorrect password. Please check your password and try again.');
      } else if (errorMessage.contains('ACCOUNT_DEACTIVATED')) {
        return AuthFailure('Your account has been deactivated. Please contact support for assistance.');
      } else {
        return AuthFailure(errorMessage);
      }
    } else if (error is NetworkException) {
      return const NetworkFailure('No internet connection. Please try again.');
    } else if (error is TimeoutException) {
      return const TimeoutFailure('Request timed out. Please try again.');
    }
    return UnknownFailure(error.toString());
  }
  
  /// Dispose repository
  void dispose() {
    _authStateController.close();
  }
}