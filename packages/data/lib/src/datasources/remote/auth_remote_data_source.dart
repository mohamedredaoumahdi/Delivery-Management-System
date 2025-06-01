import 'package:data/src/api/api_client.dart';
import 'package:core/core.dart' as core;

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
    required String confirmPassword,
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
  final core.LoggerService logger;

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
      
      // Check if response data is null/empty
      if (response.data == null) {
        throw core.ServerException('Invalid response from server: response is null');
      }

      final responseData = response.data as Map<String, dynamic>;

      // Check for server-side errors in the response body
      if (responseData.containsKey('error') && responseData['error'] != null) {
        final errorMessage = responseData['error'] is String 
            ? responseData['error'] as String
            : 'An error occurred during sign in';

        final statusCode = responseData.containsKey('statusCode') && responseData['statusCode'] is int
            ? responseData['statusCode'] as int
            : 400;

        // Throw specific exceptions based on status code
        if (statusCode == 404) {
          throw core.AuthException(errorMessage, 'ACCOUNT_NOT_FOUND');
        } else if (statusCode == 401) {
          throw core.AuthException(errorMessage, 'INCORRECT_PASSWORD');
        } else if (statusCode == 403) {
          throw core.AuthException(errorMessage, 'ACCOUNT_DEACTIVATED');
        } else {
          throw core.ServerException(errorMessage, 'HTTP_$statusCode');
        }
      }

      // Check if required fields are present in the data object
      if (!responseData.containsKey('data') || responseData['data'] == null) {
        throw core.ServerException('Invalid response from server: data is missing');
      }

      final data = responseData['data'] as Map<String, dynamic>;

      // Check if required fields are present and not null
      if (!data.containsKey('accessToken') || data['accessToken'] == null) {
        throw core.ServerException('Invalid response from server: accessToken is missing');
      }
      if (!data.containsKey('refreshToken') || data['refreshToken'] == null) {
        throw core.ServerException('Invalid response from server: refreshToken is missing');
      }
      if (!data.containsKey('user') || data['user'] == null || data['user'] is! Map<String, dynamic>) {
        throw core.ServerException('Invalid response from server: user data is missing or invalid');
      }
      
      return AuthResponseModel.fromJson(responseData);
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
    required String confirmPassword,
  }) async {
    try {
      final response = await apiClient.post(
        '/auth/register',
        data: {
          'email': email,
          'password': password,
          'name': name,
          'role': role.toUpperCase(),
          'confirmPassword': confirmPassword,
          if (phone != null) 'phone': phone,
        },
      );
      
      // Check if response data is null/empty
      if (response.data == null) {
        throw core.ServerException('Invalid response from server: response is null');
      }

      final responseData = response.data as Map<String, dynamic>;

      // Check for server-side errors in the response body
      if (responseData.containsKey('error') && responseData['error'] != null) {
        final errorMessage = responseData['error'] is String 
            ? responseData['error'] as String
            : 'An error occurred during sign up';

        final statusCode = responseData.containsKey('statusCode') && responseData['statusCode'] is int
            ? responseData['statusCode'] as int
            : 400;

        throw core.ServerException(errorMessage, 'HTTP_$statusCode');
      }

      // Check if required fields are present in the data object
      if (!responseData.containsKey('data') || responseData['data'] == null) {
        throw core.ServerException('Invalid response from server: data is missing');
      }

      final data = responseData['data'] as Map<String, dynamic>;

      // Check if required fields are present and not null
      if (!data.containsKey('accessToken') || data['accessToken'] == null) {
        throw core.ServerException('Invalid response from server: accessToken is missing');
      }
      if (!data.containsKey('refreshToken') || data['refreshToken'] == null) {
        throw core.ServerException('Invalid response from server: refreshToken is missing');
      }
      if (!data.containsKey('user') || data['user'] == null || data['user'] is! Map<String, dynamic>) {
        throw core.ServerException('Invalid response from server: user data is missing or invalid');
      }
      
      return AuthResponseModel.fromJson(responseData);
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
      final response = await apiClient.get('/users/profile');
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
      final response = await apiClient.put(
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
      await apiClient.put(
        '/users/password',
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