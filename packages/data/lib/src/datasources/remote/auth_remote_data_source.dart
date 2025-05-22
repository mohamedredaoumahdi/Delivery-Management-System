import 'package:core/core.dart';

import '../../models/user_model.dart';
import '../../models/auth_response_model.dart';

/// Interface for remote authentication data operations
abstract class AuthRemoteDataSource {
  /// Sign in with email and password
  Future<AuthResponseModel> signInWithEmailAndPassword({
    required String email,
    required String password,
  });
  
  /// Sign up with email and password
  Future<AuthResponseModel> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    required String role,
    String? phone,
  });
  
  /// Sign out
  Future<void> signOut();
  
  /// Get current user
  Future<UserModel> getCurrentUser();
  
  /// Send password reset email
  Future<void> sendPasswordResetEmail({
    required String email,
  });
  
  /// Update profile
  Future<UserModel> updateProfile({
    required String name,
    String? phone,
    String? profilePicture,
  });
  
  /// Change password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });
  
  /// Delete account
  Future<void> deleteAccount({
    required String password,
  });
}

/// Implementation of [AuthRemoteDataSource] using API client
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  /// API client
  final ApiClient apiClient;
  
  /// Logger service
  final LoggerService logger;

  /// Create auth remote data source
  AuthRemoteDataSourceImpl({
    required this.apiClient,
    required this.logger,
  });

  @override
  Future<AuthResponseModel> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final response = await apiClient.post(
        '/auth/login',
        data: {
          'email': email,
          'password': password,
        },
      );
      
      return AuthResponseModel.fromJson(response.data);
    } catch (e) {
      logger.e('Error signing in with email and password', e);
      rethrow;
    }
  }

  @override
  Future<AuthResponseModel> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    required String role,
    String? phone,
  }) async {
    try {
      final response = await apiClient.post(
        '/auth/register',
        data: {
          'email': email,
          'password': password,
          'name': name,
          'role': role,
          if (phone != null) 'phone': phone,
        },
      );
      
      return AuthResponseModel.fromJson(response.data);
    } catch (e) {
      logger.e('Error signing up with email and password', e);
      rethrow;
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await apiClient.post('/auth/logout');
    } catch (e) {
      logger.e('Error signing out', e);
      rethrow;
    }
  }

  @override
  Future<UserModel> getCurrentUser() async {
    try {
      final response = await apiClient.get('/auth/me');
      return UserModel.fromJson(response.data['data']);
    } catch (e) {
      logger.e('Error getting current user', e);
      rethrow;
    }
  }

  @override
  Future<void> sendPasswordResetEmail({
    required String email,
  }) async {
    try {
      await apiClient.post(
        '/auth/forgot-password',
        data: {
          'email': email,
        },
      );
    } catch (e) {
      logger.e('Error sending password reset email', e);
      rethrow;
    }
  }

  @override
  Future<UserModel> updateProfile({
    required String name,
    String? phone,
    String? profilePicture,
  }) async {
    try {
      final response = await apiClient.patch(
        '/users/profile',
        data: {
          'name': name,
          if (phone != null) 'phone': phone,
          if (profilePicture != null) 'profilePicture': profilePicture,
        },
      );
      
      return UserModel.fromJson(response.data['data']);
    } catch (e) {
      logger.e('Error updating profile', e);
      rethrow;
    }
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await apiClient.patch(
        '/auth/change-password',
        data: {
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        },
      );
    } catch (e) {
      logger.e('Error changing password', e);
      rethrow;
    }
  }

  @override
  Future<void> deleteAccount({
    required String password,
  }) async {
    try {
      await apiClient.delete(
        '/users/profile',
        data: {
          'password': password,
        },
      );
    } catch (e) {
      logger.e('Error deleting account', e);
      rethrow;
    }
  }
}