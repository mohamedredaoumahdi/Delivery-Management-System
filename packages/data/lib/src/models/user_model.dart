import 'package:domain/domain.dart';
import 'package:json_annotation/json_annotation.dart';

part 'user_model.g.dart';

/// Data model for User entity
@JsonSerializable()
class UserModel {
  /// Unique identifier for the user
  final String id;
  
  /// Email address of the user
  final String email;
  
  /// Full name of the user
  final String name;
  
  /// Phone number of the user
  final String? phone;
  
  /// Profile picture URL of the user
  final String? profilePicture;
  
  /// Role of the user as string
  @JsonKey(name: 'role')
  final String roleString;
  
  /// Whether the user's email is verified
  @JsonKey(name: 'isEmailVerified')
  final bool isEmailVerified;
  
  /// Whether the user's phone is verified
  @JsonKey(name: 'isPhoneVerified')
  final bool isPhoneVerified;
  
  /// Date when the user was created
  @JsonKey(name: 'createdAt', fromJson: _dateFromJson, toJson: _dateToJson)
  final DateTime createdAt;
  
  /// Date when the user was last updated
  @JsonKey(name: 'updatedAt', fromJson: _dateFromJson, toJson: _dateToJson)
  final DateTime updatedAt;

  /// Creates a user model
  UserModel({
    required this.id,
    required this.email,
    required this.name,
    this.phone,
    this.profilePicture,
    required this.roleString,
    this.isEmailVerified = false,
    this.isPhoneVerified = false,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create a model from JSON
  factory UserModel.fromJson(Map<String, dynamic> json) => _$UserModelFromJson(json);

  /// Convert model to JSON
  Map<String, dynamic> toJson() => _$UserModelToJson(this);
  
  /// Convert UserModel to User domain entity
  User toDomain() {
    // Helper function to convert relative URLs to absolute URLs
    String? toAbsoluteUrl(String? url) {
      if (url == null || url.isEmpty) return null;
      if (url.startsWith('http://') || url.startsWith('https://')) return url;
      const baseUrl = 'http://localhost:3000';
      return url.startsWith('/') ? '$baseUrl$url' : '$baseUrl/$url';
    }

    return User(
      id: id,
      email: email,
      name: name,
      phone: phone,
      profilePicture: toAbsoluteUrl(profilePicture),
      role: _mapStringToUserRole(roleString),
      isEmailVerified: isEmailVerified,
      isPhoneVerified: isPhoneVerified,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
  
  /// Create a UserModel from User domain entity
  factory UserModel.fromDomain(User user) {
    return UserModel(
      id: user.id,
      email: user.email,
      name: user.name,
      phone: user.phone,
      profilePicture: user.profilePicture,
      roleString: mapUserRoleToString(user.role),
      isEmailVerified: user.isEmailVerified,
      isPhoneVerified: user.isPhoneVerified,
      createdAt: user.createdAt,
      updatedAt: user.updatedAt,
    );
  }
  
  /// Map role string to UserRole enum
  static UserRole _mapStringToUserRole(String roleString) {
    switch (roleString.toLowerCase()) {
      case 'customer':
        return UserRole.customer;
      case 'vendor':
        return UserRole.vendor;
      case 'delivery':
        return UserRole.delivery;
      case 'admin':
        return UserRole.admin;
      default:
        return UserRole.customer;
    }
  }
  
  /// Map UserRole enum to role string
  static String mapUserRoleToString(UserRole role) {
    switch (role) {
      case UserRole.customer:
        return 'customer';
      case UserRole.vendor:
        return 'vendor';
      case UserRole.delivery:
        return 'delivery';
      case UserRole.admin:
        return 'admin';
    }
  }
  
  /// Convert timestamp to DateTime
  static DateTime _dateFromJson(dynamic json) {
    if (json is String) {
      return DateTime.parse(json);
    } else if (json is int) {
      return DateTime.fromMillisecondsSinceEpoch(json);
    } else if (json is Map && json['_seconds'] != null) {
      // Handle Firestore timestamp format
      return DateTime.fromMillisecondsSinceEpoch(
        (json['_seconds'] * 1000).toInt(),
      );
    }
    return DateTime.now();
  }
  
  /// Convert DateTime to ISO string
  static String _dateToJson(DateTime date) => date.toIso8601String();
}