import 'package:dartz/dartz.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/utils/image_url_helper.dart';
import 'package:domain/domain.dart';

class UserRepositoryImpl implements AuthRepository {
  final ApiClient _apiClient;

  UserRepositoryImpl(this._apiClient);

  @override
  Future<Either<Failure, User?>> getCurrentUser() async {
    try {
      final response = await _apiClient.get('/users/profile');
      if (response.data != null) {
        try {
          final userData = response.data['data'] as Map<String, dynamic>;
          final profilePictureUrl = ImageUrlHelper.toAbsoluteUrl(userData['profilePicture'] as String?);
          final user = User(
            id: userData['id'] as String,
            email: userData['email'] as String,
            name: userData['name'] as String,
            phone: userData['phone'] as String?,
            profilePicture: profilePictureUrl,
            role: UserRole.values.firstWhere((e) => e.toString().split('.').last == userData['role']),
            isEmailVerified: userData['isEmailVerified'] as bool,
            isPhoneVerified: userData['isPhoneVerified'] as bool,
            createdAt: DateTime.parse(userData['createdAt'] as String),
            updatedAt: DateTime.parse(userData['updatedAt'] as String),
          );
          return Right(user);
        } catch (e) {
          return const Left(ServerFailure('Failed to parse user data'));
        }
      } else {
        return const Right(null);
      }
    } on ApiException catch (e) {
      if (e.statusCode == 401 || e.statusCode == 404) {
        return const Right(null);
      }
      return Left(ServerFailure(e.message));
    } catch (e) {
      return const Left(ServerFailure('An unexpected error occurred'));
    }
  }

  @override
  Future<Either<Failure, User>> signInWithEmailAndPassword({required String email, required String password}) async {
    try {
      final response = await _apiClient.post('/auth/login', data: {
        'email': email,
        'password': password,
      });
      try {
        final userData = response.data['data']['user'] as Map<String, dynamic>;
        final accessToken = response.data['data']['accessToken'] as String;
        
        // Store the access token
        await _apiClient.setAuthToken(accessToken);
        
        final profilePictureUrl = ImageUrlHelper.toAbsoluteUrl(userData['profilePicture'] as String?);
        final user = User(
          id: userData['id'] as String,
          email: userData['email'] as String,
          name: userData['name'] as String,
          phone: userData['phone'] as String?,
          profilePicture: profilePictureUrl,
          role: UserRole.values.firstWhere((e) => e.toString().split('.').last == userData['role']),
          isEmailVerified: userData['isEmailVerified'] as bool,
          isPhoneVerified: userData['isPhoneVerified'] as bool,
          createdAt: DateTime.parse(userData['createdAt'] as String),
          updatedAt: DateTime.parse(userData['updatedAt'] as String),
        );
        return Right(user);
      } catch (e) {
        return const Left(ServerFailure('Failed to parse user data on login'));
      }
    } on ApiException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return const Left(ServerFailure('An unexpected error occurred'));
    }
  }

  @override
  Future<Either<Failure, User>> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String confirmPassword,
    required String name,
    required UserRole role,
    String? phone,
  }) async {
    try {
      final response = await _apiClient.post('/auth/register', data: {
        'email': email,
        'password': password,
        'confirmPassword': confirmPassword,
        'name': name,
        'role': role.toString().split('.').last,
        'phone': phone,
      });
      try {
        print('Response data: ${response.data}'); // Debug log
        final responseData = response.data['data'] as Map<String, dynamic>;
        print('Response data.data: $responseData'); // Debug log
        final userData = responseData['user'] as Map<String, dynamic>;
        final accessToken = responseData['accessToken'] as String;
        
        // Store the access token
        await _apiClient.setAuthToken(accessToken);
        
        final profilePictureUrl = ImageUrlHelper.toAbsoluteUrl(userData['profilePicture'] as String?);
        final user = User(
          id: userData['id'] as String,
          email: userData['email'] as String,
          name: userData['name'] as String,
          phone: userData['phone'] as String?,
          profilePicture: profilePictureUrl,
          role: UserRole.values.firstWhere((e) => e.toString().split('.').last == userData['role']),
          isEmailVerified: userData['isEmailVerified'] as bool,
          isPhoneVerified: userData['isPhoneVerified'] as bool,
          createdAt: DateTime.parse(userData['createdAt'] as String),
          updatedAt: DateTime.parse(userData['updatedAt'] as String),
        );
        return Right(user);
      } catch (e) {
        return const Left(ServerFailure('Failed to parse user data on signup'));
      }
    } on ApiException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return const Left(ServerFailure('An unexpected error occurred'));
    }
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      await _apiClient.post('/auth/logout');
      return const Right(null);
    } on ApiException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return const Left(ServerFailure('An unexpected error occurred'));
    }
  }

  @override
  Future<Either<Failure, void>> sendPasswordResetEmail({required String email}) async {
    try {
      await _apiClient.post('/auth/forgot-password', data: {
        'email': email,
      });
      return const Right(null);
    } on ApiException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return const Left(ServerFailure('An unexpected error occurred'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteAccount({required String password}) async {
    try {
      await _apiClient.delete('/auth/account?password=$password');
      return const Right(null);
    } on ApiException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return const Left(ServerFailure('An unexpected error occurred'));
    }
  }

  @override
  Future<Either<Failure, User>> updateProfile({
    required String name,
    String? phone,
    String? profilePicture,
  }) async {
    try {
      final response = await _apiClient.put('/users/profile', data: {
        'name': name,
        'phone': phone,
        'profilePicture': profilePicture,
      });
      try {
        final userData = response.data['data'] as Map<String, dynamic>;
        final profilePictureUrl = ImageUrlHelper.toAbsoluteUrl(userData['profilePicture'] as String?);
        final user = User(
          id: userData['id'] as String,
          email: userData['email'] as String,
          name: userData['name'] as String,
          phone: userData['phone'] as String?,
          profilePicture: profilePictureUrl,
          role: UserRole.values.firstWhere((e) => e.toString().split('.').last == userData['role']),
          isEmailVerified: userData['isEmailVerified'] as bool,
          isPhoneVerified: userData['isPhoneVerified'] as bool,
          createdAt: DateTime.parse(userData['createdAt'] as String),
          updatedAt: DateTime.parse(userData['updatedAt'] as String),
        );
        return Right(user);
      } catch (e) {
        return const Left(ServerFailure('Failed to parse user data'));
      }
    } on ApiException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return const Left(ServerFailure('An unexpected error occurred'));
    }
  }

  @override
  Future<Either<Failure, void>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _apiClient.put('/auth/password', data: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      });
      return const Right(null);
    } on ApiException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return const Left(ServerFailure('An unexpected error occurred'));
    }
  }
} 