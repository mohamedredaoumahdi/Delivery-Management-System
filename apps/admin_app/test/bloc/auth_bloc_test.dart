import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:admin_app/features/auth/data/admin_auth_service.dart';
import 'package:admin_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:admin_app/features/auth/presentation/bloc/auth_event.dart';
import 'package:admin_app/features/auth/presentation/bloc/auth_state.dart';

class MockAdminAuthService extends Mock implements AdminAuthService {}

void main() {
  late MockAdminAuthService mockAuthService;
  late AuthBloc authBloc;

  setUp(() {
    mockAuthService = MockAdminAuthService();
    authBloc = AuthBloc(authService: mockAuthService);
  });

  tearDown(() {
    authBloc.close();
  });

  group('AuthBloc', () {
    test('initial state is AuthInitial', () {
      expect(authBloc.state, equals(const AuthInitial()));
    });

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthAuthenticated] when login succeeds',
      build: () {
        when(() => mockAuthService.login('admin@example.com', 'password123'))
            .thenAnswer((_) async => {
                  'success': true,
                  'user': {'id': '1', 'email': 'admin@example.com', 'role': 'ADMIN'}
                });
        return authBloc;
      },
      act: (bloc) => bloc.add(const LoginRequested(
        email: 'admin@example.com',
        password: 'password123',
      )),
      expect: () => [
        const AuthLoading(),
        isA<AuthAuthenticated>(),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthError] when login fails',
      build: () {
        when(() => mockAuthService.login('admin@example.com', 'wrong'))
            .thenThrow(Exception('Invalid credentials'));
        return authBloc;
      },
      act: (bloc) => bloc.add(const LoginRequested(
        email: 'admin@example.com',
        password: 'wrong',
      )),
      expect: () => [
        const AuthLoading(),
        isA<AuthError>(),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthAuthenticated] when user is authenticated',
      build: () {
        when(() => mockAuthService.getCurrentUser())
            .thenAnswer((_) async => {'id': '1', 'email': 'admin@example.com', 'role': 'ADMIN'});
        return authBloc;
      },
      act: (bloc) => bloc.add(const CheckAuthStatus()),
      expect: () => [
        const AuthLoading(),
        isA<AuthAuthenticated>(),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthUnauthenticated] when user is not authenticated',
      build: () {
        when(() => mockAuthService.getCurrentUser())
            .thenAnswer((_) async => null);
        return authBloc;
      },
      act: (bloc) => bloc.add(const CheckAuthStatus()),
      expect: () => [
        const AuthLoading(),
        const AuthUnauthenticated(),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits AuthUnauthenticated when logout is requested',
      build: () {
        when(() => mockAuthService.logout())
            .thenAnswer((_) async => {});
        return authBloc;
      },
      act: (bloc) => bloc.add(const LogoutRequested()),
      expect: () => [
        const AuthUnauthenticated(),
      ],
    );
  });
}

