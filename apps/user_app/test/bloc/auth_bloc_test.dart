import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:domain/domain.dart';
import 'package:user_app/features/auth/presentation/bloc/auth_bloc.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockAuthRepository;
  late AuthBloc authBloc;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    authBloc = AuthBloc(authRepository: mockAuthRepository);
  });

  tearDown(() {
    authBloc.close();
  });

  group('AuthBloc', () {
    test('initial state is AuthInitial', () {
      expect(authBloc.state, isA<AuthInitial>());
    });

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthAuthenticated] when user is authenticated',
      build: () {
        final mockUser = User(
          id: '1',
          email: 'user@example.com',
          name: 'Test User',
          role: UserRole.customer,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        when(() => mockAuthRepository.getCurrentUser())
            .thenAnswer((_) async => Right(mockUser));
        return authBloc;
      },
      act: (bloc) => bloc.add(AuthCheckStatusEvent()),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthAuthenticated>(),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthUnauthenticated] when user is not authenticated',
      build: () {
        when(() => mockAuthRepository.getCurrentUser())
            .thenAnswer((_) async => const Right(null));
        return authBloc;
      },
      act: (bloc) => bloc.add(AuthCheckStatusEvent()),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthUnauthenticated>(),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthAuthenticated] when login succeeds',
      build: () {
        final mockUser = User(
          id: '1',
          email: 'user@example.com',
          name: 'Test User',
          role: UserRole.customer,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        when(() => mockAuthRepository.signInWithEmailAndPassword(
          email: 'user@example.com',
          password: 'password123',
        )).thenAnswer((_) async => Right(mockUser));
        return authBloc;
      },
      act: (bloc) => bloc.add(const AuthLoginEvent(
        email: 'user@example.com',
        password: 'password123',
      )),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthAuthenticated>(),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthError] when login fails',
      build: () {
        when(() => mockAuthRepository.signInWithEmailAndPassword(
          email: 'user@example.com',
          password: 'wrong',
        )).thenAnswer((_) async => const Left(ServerFailure('Invalid credentials')));
        return authBloc;
      },
      act: (bloc) => bloc.add(const AuthLoginEvent(
        email: 'user@example.com',
        password: 'wrong',
      )),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthError>(),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthUnauthenticated] when logout is requested',
      build: () {
        when(() => mockAuthRepository.signOut())
            .thenAnswer((_) async => const Right(null));
        return authBloc;
      },
      act: (bloc) => bloc.add(AuthLogoutEvent()),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthUnauthenticated>(),
      ],
    );
  });
}

