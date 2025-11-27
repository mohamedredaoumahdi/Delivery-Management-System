import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:admin_app/features/users/data/user_service.dart';
import 'package:admin_app/features/users/data/models/user_model.dart';
import 'package:admin_app/features/users/presentation/bloc/user_bloc.dart';
import 'package:admin_app/features/users/presentation/bloc/user_event.dart';
import 'package:admin_app/features/users/presentation/bloc/user_state.dart';

class MockUserService extends Mock implements UserService {}

void main() {
  late MockUserService mockUserService;
  late UserBloc userBloc;

  final List<UserModel> testUsers = [
    UserModel(
      id: '1',
      email: 'user1@example.com',
      name: 'User 1',
      role: 'CUSTOMER',
      isActive: true,
      isEmailVerified: true,
      isPhoneVerified: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    UserModel(
      id: '2',
      email: 'user2@example.com',
      name: 'User 2',
      role: 'VENDOR',
      isActive: true,
      isEmailVerified: true,
      isPhoneVerified: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
  ];

  setUp(() {
    mockUserService = MockUserService();
    userBloc = UserBloc(userService: mockUserService);
  });

  tearDown(() {
    userBloc.close();
  });

  group('UserBloc', () {
    test('initial state is UserInitial', () {
      expect(userBloc.state, equals(const UserInitial()));
    });

    blocTest<UserBloc, UserState>(
      'emits [UserLoading, UsersLoaded] when users load successfully',
      build: () {
        when(() => mockUserService.getUsers())
            .thenAnswer((_) async => testUsers);
        return userBloc;
      },
      act: (bloc) => bloc.add(const LoadUsers()),
      expect: () => [
        const UserLoading(),
        isA<UsersLoaded>()
          ..having((s) => s.users.length, 'users.length', 2)
          ..having((s) => s.filteredUsers.length, 'filteredUsers.length', 2),
      ],
    );

    blocTest<UserBloc, UserState>(
      'emits [UserLoading, UserError] when users load fails',
      build: () {
        when(() => mockUserService.getUsers())
            .thenThrow(Exception('Network error'));
        return userBloc;
      },
      act: (bloc) => bloc.add(const LoadUsers()),
      expect: () => [
        const UserLoading(),
        isA<UserError>(),
      ],
    );

    blocTest<UserBloc, UserState>(
      'filters users by role',
      build: () {
        when(() => mockUserService.getUsers())
            .thenAnswer((_) async => testUsers);
        return userBloc;
      },
      seed: () => UsersLoaded(
        users: testUsers,
        filteredUsers: testUsers,
        selectedRole: null,
        searchQuery: null,
      ),
      act: (bloc) => bloc.add(const FilterUsers(role: 'CUSTOMER')),
      expect: () => [
        isA<UsersLoaded>()
          ..having((s) => s.selectedRole, 'selectedRole', 'CUSTOMER')
          ..having((s) => s.filteredUsers.length, 'filteredUsers.length', 1),
      ],
    );

    blocTest<UserBloc, UserState>(
      'filters users by search query',
      build: () {
        when(() => mockUserService.getUsers())
            .thenAnswer((_) async => testUsers);
        return userBloc;
      },
      seed: () => UsersLoaded(
        users: testUsers,
        filteredUsers: testUsers,
        selectedRole: null,
        searchQuery: null,
      ),
      act: (bloc) => bloc.add(const FilterUsers(searchQuery: 'User 1')),
      expect: () => [
        isA<UsersLoaded>()
          ..having((s) => s.searchQuery, 'searchQuery', 'User 1')
          ..having((s) => s.filteredUsers.length, 'filteredUsers.length', 1),
      ],
    );

    blocTest<UserBloc, UserState>(
      'deletes user successfully',
      build: () {
        when(() => mockUserService.deleteUser('1'))
            .thenAnswer((_) async => {});
        when(() => mockUserService.getUsers())
            .thenAnswer((_) async => [testUsers[1]]);
        return userBloc;
      },
      seed: () => UsersLoaded(
        users: testUsers,
        filteredUsers: testUsers,
        selectedRole: null,
        searchQuery: null,
      ),
      act: (bloc) => bloc.add(const DeleteUser('1')),
      verify: (_) {
        verify(() => mockUserService.deleteUser('1')).called(1);
      },
    );
  });
}

