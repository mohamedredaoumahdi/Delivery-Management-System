// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserModel _$UserModelFromJson(Map<String, dynamic> json) => UserModel(
  id: json['id'] as String,
  email: json['email'] as String,
  name: json['name'] as String,
  phone: json['phone'] as String?,
  profilePicture: json['profilePicture'] as String?,
  roleString: json['role'] as String,
  isEmailVerified: json['isEmailVerified'] as bool? ?? false,
  isPhoneVerified: json['isPhoneVerified'] as bool? ?? false,
  createdAt: UserModel._dateFromJson(json['createdAt']),
  updatedAt: UserModel._dateFromJson(json['updatedAt']),
);

Map<String, dynamic> _$UserModelToJson(UserModel instance) => <String, dynamic>{
  'id': instance.id,
  'email': instance.email,
  'name': instance.name,
  'phone': instance.phone,
  'profilePicture': instance.profilePicture,
  'role': instance.roleString,
  'isEmailVerified': instance.isEmailVerified,
  'isPhoneVerified': instance.isPhoneVerified,
  'createdAt': UserModel._dateToJson(instance.createdAt),
  'updatedAt': UserModel._dateToJson(instance.updatedAt),
};
