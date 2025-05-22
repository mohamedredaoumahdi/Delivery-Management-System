import 'package:data/data.dart';
import 'package:core/core.dart';
import '../../models/user_model.dart';
import '../../models/auth_response_model.dart';

class MockAuthRemoteDataSource implements AuthRemoteDataSource {
  static const String _mockEmail = 'test@example.com';
  static const String _mockPassword = 'password123';
  static const String _mockToken = 'mock_token_123';

  UserModel? _mockUser;
  bool _signedIn = false;

  MockAuthRemoteDataSource() {
    _mockUser = UserModel(
      id: 'mock_user_1',
      email: _mockEmail,
      name: 'Test User',
      phone: '1234567890',
      profilePicture: null,
      roleString: 'customer',
      isEmailVerified: true,
      isPhoneVerified: true,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<AuthResponseModel> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (email == _mockEmail && password == _mockPassword) {
      _signedIn = true;
      return AuthResponseModel(token: _mockToken, user: _mockUser!);
    } else {
      throw ApiException(message: 'Invalid email or password');
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
    await Future.delayed(const Duration(milliseconds: 500));
    // For mock, just return the same user
    if (email == _mockEmail) {
      throw ApiException(message: 'User already exists');
    }
    _mockUser = UserModel(
      id: 'mock_user_2',
      email: email,
      name: name,
      phone: phone,
      profilePicture: null,
      roleString: role,
      isEmailVerified: false,
      isPhoneVerified: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _signedIn = true;
    return AuthResponseModel(token: _mockToken, user: _mockUser!);
  }

  @override
  Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _signedIn = false;
  }

  @override
  Future<UserModel> getCurrentUser() async {
    await Future.delayed(const Duration(milliseconds: 200));
    if (_signedIn && _mockUser != null) {
      return _mockUser!;
    } else {
      throw ApiException(message: 'No user signed in');
    }
  }

  @override
  Future<void> sendPasswordResetEmail({
    required String email,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    if (email == _mockEmail) {
      // Simulate success
      return;
    } else {
      throw ApiException(message: 'Email not found');
    }
  }

  @override
  Future<UserModel> updateProfile({
    required String name,
    String? phone,
    String? profilePicture,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    if (_mockUser == null) throw ApiException(message: 'No user signed in');
    _mockUser = UserModel(
      id: _mockUser!.id,
      email: _mockUser!.email,
      name: name,
      phone: phone ?? _mockUser!.phone,
      profilePicture: profilePicture ?? _mockUser!.profilePicture,
      roleString: _mockUser!.roleString,
      isEmailVerified: _mockUser!.isEmailVerified,
      isPhoneVerified: _mockUser!.isPhoneVerified,
      createdAt: _mockUser!.createdAt,
      updatedAt: DateTime.now(),
    );
    return _mockUser!;
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    if (!_signedIn) throw ApiException(message: 'No user signed in');
    if (currentPassword != _mockPassword) throw ApiException(message: 'Current password incorrect');
    // For mock, do nothing
  }

  @override
  Future<void> deleteAccount({
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    if (!_signedIn) throw ApiException(message: 'No user signed in');
    if (password != _mockPassword) throw ApiException(message: 'Password incorrect');
    _signedIn = false;
    _mockUser = null;
  }
}
