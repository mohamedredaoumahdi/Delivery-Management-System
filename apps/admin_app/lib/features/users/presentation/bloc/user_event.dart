import 'package:equatable/equatable.dart';

abstract class UserEvent extends Equatable {
  const UserEvent();

  @override
  List<Object?> get props => [];
}

class LoadUsers extends UserEvent {
  const LoadUsers();
}

class RefreshUsers extends UserEvent {
  const RefreshUsers();
}

class LoadUserDetails extends UserEvent {
  final String userId;

  const LoadUserDetails(this.userId);

  @override
  List<Object?> get props => [userId];
}

class UpdateUser extends UserEvent {
  final String userId;
  final Map<String, dynamic> data;

  const UpdateUser(this.userId, this.data);

  @override
  List<Object?> get props => [userId, data];
}

class DeleteUser extends UserEvent {
  final String userId;

  const DeleteUser(this.userId);

  @override
  List<Object?> get props => [userId];
}

class CreateUser extends UserEvent {
  final Map<String, dynamic> data;

  const CreateUser(this.data);

  @override
  List<Object?> get props => [data];
}

class FilterUsers extends UserEvent {
  final String? role;
  final String? searchQuery;

  const FilterUsers({this.role, this.searchQuery});

  @override
  List<Object?> get props => [role, searchQuery];
}

