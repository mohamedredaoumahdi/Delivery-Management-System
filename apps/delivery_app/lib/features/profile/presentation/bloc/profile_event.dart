part of 'profile_bloc.dart';

abstract class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object?> get props => [];
}

class ProfileLoadEvent extends ProfileEvent {
  const ProfileLoadEvent();
}

class ProfileUpdateEvent extends ProfileEvent {
  final String? name;
  final String? phone;
  final String? vehicleType;
  final String? licenseNumber;

  const ProfileUpdateEvent({
    this.name,
    this.phone,
    this.vehicleType,
    this.licenseNumber,
  });

  @override
  List<Object?> get props => [name, phone, vehicleType, licenseNumber];
}

class ProfileLogoutEvent extends ProfileEvent {
  final BuildContext context;
  
  const ProfileLogoutEvent(this.context);

  @override
  List<Object?> get props => [context];
} 