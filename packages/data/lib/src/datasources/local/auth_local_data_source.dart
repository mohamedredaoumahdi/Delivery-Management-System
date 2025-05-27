import 'package:core/core.dart';

/// Interface for local authentication data operations
abstract class AuthLocalDataSource {
  /// Save authentication token
  Future<void> saveAuthToken(String token);
  
  /// Get authentication token
  Future<String?> getAuthToken();
  
  /// Clear authentication token
  Future<void> clearAuthToken();
  
  /// Save refresh token
  Future<void> saveRefreshToken(String token);
  
  /// Get refresh token
  Future<String?> getRefreshToken();
  
  /// Clear refresh token
  Future<void> clearRefreshToken();
  
  /// Save user ID
  Future<void> saveUserId(String userId);
  
  /// Get user ID
  Future<String?> getUserId();
  
  /// Clear user ID
  Future<void> clearUserId();
  
  /// Clear all auth data
  Future<void> clearAllAuthData();
}

/// Implementation of [AuthLocalDataSource] using [StorageService]
class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  /// Storage service
  final StorageService storageService;
  
  /// Logger service
  final LoggerService logger;
  
  /// Key for auth token
  static const String _authTokenKey = 'auth_token';
  
  /// Key for refresh token
  static const String _refreshTokenKey = 'refresh_token';
  
  /// Key for user ID
  static const String _userIdKey = 'user_id';

  /// Create auth local data source
  AuthLocalDataSourceImpl({
    required this.storageService,
    required this.logger,
  });

  @override
  Future<void> saveAuthToken(String token) async {
    try {
      await storageService.setString(_authTokenKey, token);
      logger.d('Auth token saved');
    } catch (e) {
      logger.e('Error saving auth token', e);
      rethrow;
    }
  }

  @override
  Future<String?> getAuthToken() async {
    try {
      return storageService.getString(_authTokenKey);
    } catch (e) {
      logger.e('Error getting auth token', e);
      return null;
    }
  }

  @override
  Future<void> clearAuthToken() async {
    try {
      await storageService.remove(_authTokenKey);
      logger.d('Auth token cleared');
    } catch (e) {
      logger.e('Error clearing auth token', e);
      rethrow;
    }
  }

  @override
  Future<void> saveRefreshToken(String token) async {
    try {
      await storageService.setString(_refreshTokenKey, token);
      logger.d('Refresh token saved');
    } catch (e) {
      logger.e('Error saving refresh token', e);
      rethrow;
    }
  }

  @override
  Future<String?> getRefreshToken() async {
    try {
      return storageService.getString(_refreshTokenKey);
    } catch (e) {
      logger.e('Error getting refresh token', e);
      return null;
    }
  }

  @override
  Future<void> clearRefreshToken() async {
    try {
      await storageService.remove(_refreshTokenKey);
      logger.d('Refresh token cleared');
    } catch (e) {
      logger.e('Error clearing refresh token', e);
      rethrow;
    }
  }

  @override
  Future<void> saveUserId(String userId) async {
    try {
      await storageService.setString(_userIdKey, userId);
      logger.d('User ID saved');
    } catch (e) {
      logger.e('Error saving user ID', e);
      rethrow;
    }
  }

  @override
  Future<String?> getUserId() async {
    try {
      return storageService.getString(_userIdKey);
    } catch (e) {
      logger.e('Error getting user ID', e);
      return null;
    }
  }

  @override
  Future<void> clearUserId() async {
    try {
      await storageService.remove(_userIdKey);
      logger.d('User ID cleared');
    } catch (e) {
      logger.e('Error clearing user ID', e);
      rethrow;
    }
  }

  @override
  Future<void> clearAllAuthData() async {
    try {
      await Future.wait([
        clearAuthToken(),
        clearRefreshToken(),
        clearUserId(),
      ]);
      logger.d('All auth data cleared');
    } catch (e) {
      logger.e('Error clearing all auth data', e);
      rethrow;
    }
  }
}