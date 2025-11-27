import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:go_router/go_router.dart';
import '../../data/profile_service.dart';
import '../../domain/models/driver_user.dart';

part 'profile_event.dart';
part 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final ProfileService _profileService;

  ProfileBloc(this._profileService) : super(const ProfileInitial()) {
    on<ProfileLoadEvent>(_onLoadProfile);
    on<ProfileUpdateEvent>(_onUpdateProfile);
    on<ProfileLogoutEvent>(_onLogout);
  }

  Future<void> _onLoadProfile(
    ProfileLoadEvent event,
    Emitter<ProfileState> emit,
  ) async {
    print('🚀 ProfileBloc: LoadEvent received');
    print('📊 ProfileBloc: Current state: ${state.runtimeType}');
    
    emit(const ProfileLoading());
    print('📊 ProfileBloc: State updated to ProfileLoading');

    try {
      print('🔄 ProfileBloc: Calling profileService.getProfile()');
      final profileData = await _profileService.getProfile();
      print('✅ ProfileBloc: Successfully received profile data');
      print('📦 ProfileBloc: Profile data: $profileData');
      
      final profile = DriverUser(
        id: profileData['id'] ?? '',
        email: profileData['email'] ?? '',
        name: profileData['name'] ?? 'Delivery Driver',
        phone: profileData['phone'] ?? '',
        vehicleType: profileData['vehicleType'] ?? 'Car',
        licenseNumber: profileData['licenseNumber'] ?? 'DL123456',
        isActive: profileData['isActive'] ?? true,
      );
      
      print('✅ ProfileBloc: Converted to DriverUser successfully');
      emit(ProfileLoaded(profile));
      print('📊 ProfileBloc: Emitted ProfileLoaded state');
    } catch (error) {
      print('❌ ProfileBloc: Error loading profile: $error');
      print('❌ ProfileBloc: Error type: ${error.runtimeType}');
      emit(ProfileError(error.toString()));
      print('📊 ProfileBloc: Emitted ProfileError state: $error');
    }
  }

  Future<void> _onUpdateProfile(
    ProfileUpdateEvent event,
    Emitter<ProfileState> emit,
  ) async {
    print('🚀 ProfileBloc: UpdateEvent received');
    
    try {
      print('🔄 ProfileBloc: Calling profileService.updateProfile()');
      await _profileService.updateProfile(
        name: event.name,
        phone: event.phone,
        vehicleType: event.vehicleType,
        licenseNumber: event.licenseNumber,
      );
      
      print('✅ ProfileBloc: Profile updated successfully');
      
      // Reload profile to get updated data
      final profileData = await _profileService.getProfile();
      final profile = DriverUser(
        id: profileData['id'] ?? '',
        email: profileData['email'] ?? '',
        name: profileData['name'] ?? 'Delivery Driver',
        phone: profileData['phone'] ?? '',
        vehicleType: profileData['vehicleType'] ?? 'Car',
        licenseNumber: profileData['licenseNumber'] ?? 'DL123456',
        isActive: profileData['isActive'] ?? true,
      );
      
      emit(ProfileLoaded(profile));
      print('📊 ProfileBloc: Emitted ProfileLoaded state with updated data');
    } catch (error) {
      print('❌ ProfileBloc: Error updating profile: $error');
      emit(ProfileError(error.toString()));
    }
  }

  Future<void> _onLogout(
    ProfileLogoutEvent event,
    Emitter<ProfileState> emit,
  ) async {
    print('🚀 ProfileBloc: LogoutEvent received');
    print('📊 ProfileBloc: Current state: ${state.runtimeType}');
    
    emit(const ProfileLoading());
    print('📊 ProfileBloc: State updated to ProfileLoading');

    try {
      print('🔄 ProfileBloc: Calling profileService.logout()');
      await _profileService.logout();
      print('✅ ProfileBloc: Logout successful');
      
      // Navigate to login page
      print('🔄 ProfileBloc: Navigating to login page');
      GoRouter.of(event.context).go('/login');
    } catch (error) {
      print('❌ ProfileBloc: Error during logout: $error');
      print('❌ ProfileBloc: Error type: ${error.runtimeType}');
      emit(ProfileError(error.toString()));
      print('📊 ProfileBloc: Emitted ProfileError state: $error');
    }
  }
} 