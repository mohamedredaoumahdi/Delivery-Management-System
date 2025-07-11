import 'package:equatable/equatable.dart';

class Address extends Equatable {
  final String id;
  final String label;
  final String fullAddress;
  final double latitude;
  final double longitude;
  final String? instructions;
  final bool isDefault;
  final String userId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Address({
    required this.id,
    required this.label,
    required this.fullAddress,
    required this.latitude,
    required this.longitude,
    this.instructions,
    required this.isDefault,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      id: json['id'] as String,
      label: json['label'] as String,
      fullAddress: json['fullAddress'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      instructions: json['instructions'] as String?,
      isDefault: json['isDefault'] as bool,
      userId: json['userId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'fullAddress': fullAddress,
      'latitude': latitude,
      'longitude': longitude,
      'instructions': instructions,
      'isDefault': isDefault,
      'userId': userId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Address copyWith({
    String? id,
    String? label,
    String? fullAddress,
    double? latitude,
    double? longitude,
    String? instructions,
    bool? isDefault,
    String? userId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Address(
      id: id ?? this.id,
      label: label ?? this.label,
      fullAddress: fullAddress ?? this.fullAddress,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      instructions: instructions ?? this.instructions,
      isDefault: isDefault ?? this.isDefault,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        label,
        fullAddress,
        latitude,
        longitude,
        instructions,
        isDefault,
        userId,
        createdAt,
        updatedAt,
      ];
} 