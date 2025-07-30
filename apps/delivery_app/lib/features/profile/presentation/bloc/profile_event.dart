part of 'profile_bloc.dart';

abstract class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object?> get props => [];
}

class ProfileLoadEvent extends ProfileEvent {
  const ProfileLoadEvent();
}

class ProfileLogoutEvent extends ProfileEvent {
  final BuildContext context;
  
  const ProfileLogoutEvent(this.context);

  @override
  List<Object?> get props => [context];
} 