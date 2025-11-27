import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vendor_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vendor_app/di/injection_container.dart';

class MockAuthService extends Mock implements AuthService {}

void main() {
  late MockAuthService mockAuthService;
  late AuthBloc authBloc;

  setUp(() {
    mockAuthService = MockAuthService();
    authBloc = AuthBloc(authService: mockAuthService);
  });

  tearDown(() {
    authBloc.close();
  });

  group('Vendor AuthBloc', () {
    test('initial state is AuthInitial', () {
      expect(authBloc.state, isA<AuthInitial>());
    });

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthAuthenticated] when login succeeds',
      build: () {
        when(() => mockAuthService.login('vendor@example.com', 'password123'))
            .thenAnswer((_) async => {
                  'success': true,
                  'user': {
                    'id': '1',
                    'email': 'vendor@example.com',
                    'name': 'Test Vendor',
                    'role': 'VENDOR',
                  }
                });
        return authBloc;
      },
      act: (bloc) => bloc.add(const LoginRequested(
        email: 'vendor@example.com',
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
        when(() => mockAuthService.login('vendor@example.com', 'wrong'))
            .thenThrow(Exception('Invalid credentials'));
        return authBloc;
      },
      act: (bloc) => bloc.add(const LoginRequested(
        email: 'vendor@example.com',
        password: 'wrong',
      )),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthError>(),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthAuthenticated] when registration succeeds',
      build: () {
        when(() => mockAuthService.register(any()))
            .thenAnswer((_) async => {
                  'success': true,
                  'user': {
                    'id': '1',
                    'email': 'vendor@example.com',
                    'name': 'Test Vendor',
                    'role': 'VENDOR',
                  }
                });
        return authBloc;
      },
      act: (bloc) => bloc.add(const RegisterRequested(
        name: 'Test Vendor',
        email: 'vendor@example.com',
        password: 'password123',
        phone: '+1234567890',
        businessName: 'Test Restaurant',
        businessAddress: '123 Test St',
      )),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthAuthenticated>(),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthUnauthenticated] when logout succeeds',
      build: () {
        when(() => mockAuthService.logout())
            .thenAnswer((_) async => {});
        return authBloc;
      },
      act: (bloc) => bloc.add(LogoutRequested()),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthUnauthenticated>(),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthAuthenticated] when user is authenticated',
      build: () {
        when(() => mockAuthService.getCurrentUser())
            .thenAnswer((_) async => {
                  'id': '1',
                  'email': 'vendor@example.com',
                  'name': 'Test Vendor',
                  'role': 'VENDOR',
                });
        return authBloc;
      },
      act: (bloc) => bloc.add(CheckAuthStatus()),
      expect: () => [
        isA<AuthLoading>(),
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
      act: (bloc) => bloc.add(CheckAuthStatus()),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthUnauthenticated>(),
      ],
    );
  });
}
