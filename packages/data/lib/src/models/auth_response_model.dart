import 'package:json_annotation/json_annotation.dart';

import 'user_model.dart';

part 'auth_response_model.g.dart';

/// Data model for authentication response
@JsonSerializable()
class AuthResponseModel {
  final String status;
  final String message;
  final AuthDataModel data;

  /// Creates an auth response model
  AuthResponseModel({
    required this.status,
    required this.message,
    required this.data,
  });

  /// Create a model from JSON
  factory AuthResponseModel.fromJson(Map<String, dynamic> json) => _$AuthResponseModelFromJson(json);

  /// Convert model to JSON
  Map<String, dynamic> toJson() => _$AuthResponseModelToJson(this);
}

@JsonSerializable()
class AuthDataModel {
  @JsonKey(name: 'accessToken')
  final String token;
  final UserModel user;

  AuthDataModel({
    required this.token,
    required this.user,
  });

  factory AuthDataModel.fromJson(Map<String, dynamic> json) => _$AuthDataModelFromJson(json);
  Map<String, dynamic> toJson() => _$AuthDataModelToJson(this);
}