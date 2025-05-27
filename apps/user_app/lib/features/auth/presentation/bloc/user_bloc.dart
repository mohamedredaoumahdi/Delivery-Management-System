import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:domain/domain.dart' as domain;
import '../../domain/repositories/user_repository.dart';

// Events
abstract class UserEvent extends Equatable {
  const UserEvent();

  @override
  List<Object?> get props => [];
}

class GetProfile extends UserEvent {}

class UpdateProfile extends UserEvent {
  final Map<String, dynamic> data;

  const UpdateProfile(this.data);

  @override
  List<Object?> get props => [data];
}

class ChangePassword extends UserEvent {
  final String currentPassword;
  final String newPassword;

  const ChangePassword({
    required this.currentPassword,
    required this.newPassword,
  });

  @override
  List<Object?> get props => [currentPassword, newPassword];
}

// States
abstract class UserState extends Equatable {
  const UserState();

  @override
  List<Object?> get props => [];
}

class UserInitial extends UserState {}

class UserLoading extends UserState {}

class UserLoaded extends UserState {
  final domain.User user;

  const UserLoaded(this.user);

  @override
  List<Object?> get props => [user];
}

class UserError extends UserState {
  final String message;

  const UserError(this.message);

  @override
  List<Object?> get props => [message];
}

// Bloc
class UserBloc extends Bloc<UserEvent, UserState> {
  final UserRepository _userRepository;

  UserBloc(this._userRepository) : super(UserInitial()) {
    on<GetProfile>(_onGetProfile);
    on<UpdateProfile>(_onUpdateProfile);
    on<ChangePassword>(_onChangePassword);
  }

  Future<void> _onGetProfile(GetProfile event, Emitter<UserState> emit) async {
    emit(UserLoading());
    final result = await _userRepository.getProfile();
    result.fold(
      (failure) => emit(UserError(failure.message)),
      (user) => emit(UserLoaded(user)),
    );
  }

  Future<void> _onUpdateProfile(UpdateProfile event, Emitter<UserState> emit) async {
    emit(UserLoading());
    final result = await _userRepository.updateProfile(event.data);
    result.fold(
      (failure) => emit(UserError(failure.message)),
      (user) => emit(UserLoaded(user)),
    );
  }

  Future<void> _onChangePassword(ChangePassword event, Emitter<UserState> emit) async {
    emit(UserLoading());
    final result = await _userRepository.changePassword(
      event.currentPassword,
      event.newPassword,
    );
    result.fold(
      (failure) => emit(UserError(failure.message)),
      (_) => emit(UserInitial()),
    );
  }
} 