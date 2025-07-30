import 'package:equatable/equatable.dart';

class DriverUser extends Equatable {
  final String id;
  final String email;
  final String name;
  final String phone;
  final String vehicleType;
  final String licenseNumber;
  final bool isActive;

  const DriverUser({
    required this.id,
    required this.email,
    required this.name,
    required this.phone,
    required this.vehicleType,
    required this.licenseNumber,
    required this.isActive,
  });

  @override
  List<Object?> get props => [
    id,
    email,
    name,
    phone,
    vehicleType,
    licenseNumber,
    isActive,
  ];

  @override
  String toString() {
    return 'DriverUser(id: $id, name: $name, email: $email, phone: $phone, vehicleType: $vehicleType, licenseNumber: $licenseNumber, isActive: $isActive)';
  }
} 