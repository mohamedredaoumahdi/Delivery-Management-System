import 'package:equatable/equatable.dart';
import '../../data/models/user_model.dart';

abstract class UserState extends Equatable {
  const UserState();

  @override
  List<Object?> get props => [];
}

class UserInitial extends UserState {
  const UserInitial();
}

class UserLoading extends UserState {
  const UserLoading();
}

class UsersLoaded extends UserState {
  final List<UserModel> users;
  final List<UserModel> filteredUsers;
  final String? selectedRole;
  final String? searchQuery;

  const UsersLoaded({
    required this.users,
    required this.filteredUsers,
    this.selectedRole,
    this.searchQuery,
  });

  @override
  List<Object?> get props => [users, filteredUsers, selectedRole, searchQuery];

  UsersLoaded copyWith({
    List<UserModel>? users,
    List<UserModel>? filteredUsers,
    String? selectedRole,
    String? searchQuery,
  }) {
    return UsersLoaded(
      users: users ?? this.users,
      filteredUsers: filteredUsers ?? this.filteredUsers,
      selectedRole: selectedRole ?? this.selectedRole,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class UserDetailsLoaded extends UserState {
  final UserModel user;

  const UserDetailsLoaded(this.user);

  @override
  List<Object?> get props => [user];
}

class UserError extends UserState {
  final String message;

  const UserError(this.message);

  @override
  List<Object?> get props => [message];
}

class UserUpdated extends UserState {
  final UserModel user;

  const UserUpdated(this.user);

  @override
  List<Object?> get props => [user];
}

class UserCreated extends UserState {
  final UserModel user;

  const UserCreated(this.user);

  @override
  List<Object?> get props => [user];
}

class UserDeleted extends UserState {
  const UserDeleted();
}

