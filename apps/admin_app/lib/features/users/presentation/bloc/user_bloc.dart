import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/user_service.dart';
import '../../data/models/user_model.dart';
import 'user_event.dart';
import 'user_state.dart';

class UserBloc extends Bloc<UserEvent, UserState> {
  final UserService userService;

  UserBloc({required this.userService}) : super(const UserInitial()) {
    on<LoadUsers>(_onLoadUsers);
    on<RefreshUsers>(_onRefreshUsers);
    on<LoadUserDetails>(_onLoadUserDetails);
    on<UpdateUser>(_onUpdateUser);
    on<DeleteUser>(_onDeleteUser);
    on<CreateUser>(_onCreateUser);
    on<FilterUsers>(_onFilterUsers);
  }

  Future<void> _onLoadUsers(LoadUsers event, Emitter<UserState> emit) async {
    emit(const UserLoading());
    try {
      final users = await userService.getUsers();
      emit(UsersLoaded(
        users: users,
        filteredUsers: users,
        selectedRole: null,
        searchQuery: null,
      ));
    } catch (e) {
      emit(UserError(e.toString()));
    }
  }

  Future<void> _onRefreshUsers(RefreshUsers event, Emitter<UserState> emit) async {
    try {
      final users = await userService.getUsers();
      if (state is UsersLoaded) {
        final currentState = state as UsersLoaded;
        final filteredUsers = _applyFilters(
          users,
          role: currentState.selectedRole,
          searchQuery: currentState.searchQuery,
        );
        emit(UsersLoaded(
          users: users,
          filteredUsers: filteredUsers,
          selectedRole: currentState.selectedRole,
          searchQuery: currentState.searchQuery,
        ));
      } else {
        emit(UsersLoaded(
          users: users,
          filteredUsers: users,
          selectedRole: null,
          searchQuery: null,
        ));
      }
    } catch (e) {
      emit(UserError(e.toString()));
    }
  }

  Future<void> _onLoadUserDetails(LoadUserDetails event, Emitter<UserState> emit) async {
    emit(const UserLoading());
    try {
      final user = await userService.getUserById(event.userId);
      emit(UserDetailsLoaded(user));
    } catch (e) {
      emit(UserError(e.toString()));
    }
  }

  Future<void> _onUpdateUser(UpdateUser event, Emitter<UserState> emit) async {
    final previousState = state;
    try {
      final updatedUser = await userService.updateUser(event.userId, event.data);
      emit(UserUpdated(updatedUser));
      await _reloadUsersWithFilters(emit, previousState);
    } catch (e) {
      emit(UserError(e.toString()));
      if (previousState is UsersLoaded) {
        emit(previousState);
      }
    }
  }

  Future<void> _onDeleteUser(DeleteUser event, Emitter<UserState> emit) async {
    final previousState = state;
    try {
      await userService.deleteUser(event.userId);
      emit(const UserDeleted());
      await _reloadUsersWithFilters(emit, previousState);
    } catch (e) {
      emit(UserError(e.toString()));
      if (previousState is UsersLoaded) {
        emit(previousState);
      }
    }
  }

  Future<void> _onCreateUser(CreateUser event, Emitter<UserState> emit) async {
    final previousState = state;
    try {
      final newUser = await userService.createUser(event.data);
      emit(UserCreated(newUser));
      await _reloadUsersWithFilters(emit, previousState);
    } catch (e) {
      emit(UserError(e.toString()));
      if (previousState is UsersLoaded) {
        emit(previousState);
      }
    }
  }

  void _onFilterUsers(FilterUsers event, Emitter<UserState> emit) {
    if (state is UsersLoaded) {
      final currentState = state as UsersLoaded;
      final filteredUsers = _applyFilters(
        currentState.users,
        role: event.role,
        searchQuery: event.searchQuery,
      );
      emit(UsersLoaded(
        users: currentState.users,
        filteredUsers: filteredUsers,
        selectedRole: event.role,
        searchQuery: event.searchQuery,
      ));
    }
  }

  List<UserModel> _applyFilters(
    List<UserModel> users, {
    String? role,
    String? searchQuery,
  }) {
    var filtered = List<UserModel>.from(users);

    // Apply role filter
    if (role != null && role.isNotEmpty) {
      filtered = filtered.where((user) => user.role == role).toList();
    }

    // Apply search query
    if (searchQuery != null && searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase().trim();
      filtered = filtered.where((user) {
        final name = user.name.toLowerCase();
        final email = user.email.toLowerCase();
        final phone = user.phone?.toLowerCase() ?? '';
        
        return name.contains(query) ||
            email.contains(query) ||
            phone.contains(query);
      }).toList();
    }

    return filtered;
  }

  Future<void> _reloadUsersWithFilters(Emitter<UserState> emit, UserState previousState) async {
    final users = await userService.getUsers();
    if (previousState is UsersLoaded) {
      final filteredUsers = _applyFilters(
        users,
        role: previousState.selectedRole,
        searchQuery: previousState.searchQuery,
      );
      emit(UsersLoaded(
        users: users,
        filteredUsers: filteredUsers,
        selectedRole: previousState.selectedRole,
        searchQuery: previousState.searchQuery,
      ));
    } else {
      emit(UsersLoaded(
        users: users,
        filteredUsers: users,
        selectedRole: null,
        searchQuery: null,
      ));
    }
  }
}

