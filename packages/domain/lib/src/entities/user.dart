import 'package:equatable/equatable.dart';

/// Enum representing the user roles
enum UserRole {
  /// Customer role
  customer,
  
  /// Vendor/Shop owner role
  vendor,
  
  /// Delivery personnel role
  delivery,
  
  /// Admin role
  admin,
}

/// User entity representing a user in the system
class User extends Equatable {
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
  
  /// Role of the user
  final UserRole role;
  
  /// Whether the user's email is verified
  final bool isEmailVerified;
  
  /// Whether the user's phone is verified
  final bool isPhoneVerified;
  
  /// Date when the user was created
  final DateTime createdAt;
  
  /// Date when the user was last updated
  final DateTime updatedAt;

  /// Creates a user entity
  const User({
    required this.id,
    required this.email,
    required this.name,
    this.phone,
    this.profilePicture,
    required this.role,
    this.isEmailVerified = false,
    this.isPhoneVerified = false,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Creates a copy of this user with the given fields replaced
  User copyWith({
    String? id,
    String? email,
    String? name,
    String? Function()? phone,
    String? Function()? profilePicture,
    UserRole? role,
    bool? isEmailVerified,
    bool? isPhoneVerified,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      phone: phone != null ? phone() : this.phone,
      profilePicture: profilePicture != null ? profilePicture() : this.profilePicture,
      role: role ?? this.role,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      isPhoneVerified: isPhoneVerified ?? this.isPhoneVerified,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
  
  /// Empty user instance
  factory User.empty() {
    return User(
      id: '',
      email: '',
      name: '',
      role: UserRole.customer,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
  
  @override
  List<Object?> get props => [
    id, email, name, phone, profilePicture, role, 
    isEmailVerified, isPhoneVerified, createdAt, updatedAt,
  ];
}