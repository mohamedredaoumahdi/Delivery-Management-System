import 'package:json_annotation/json_annotation.dart';

import 'user_model.dart';

part 'auth_response_model.g.dart';

/// Data model for authentication response
@JsonSerializable()
class AuthResponseModel {
  /// Authentication token
  final String token;
  
  /// User data
  final UserModel user;

  /// Creates an auth response model
  AuthResponseModel({
    required this.token,
    required this.user,
  });

  /// Create a model from JSON
  factory AuthResponseModel.fromJson(Map<String, dynamic> json) => _$AuthResponseModelFromJson(json);

  /// Convert model to JSON
  Map<String, dynamic> toJson() => _$AuthResponseModelToJson(this);
}