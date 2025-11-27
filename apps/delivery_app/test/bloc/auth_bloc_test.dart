import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:delivery_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:delivery_app/features/auth/data/auth_service.dart';

class MockAuthService extends Mock implements AuthService {}

void main() {
  late MockAuthService mockAuthService;
  late AuthBloc authBloc;

  setUp(() {
    mockAuthService = MockAuthService();
    authBloc = AuthBloc(mockAuthService);
  });

  tearDown(() {
    authBloc.close();
  });

  group('Delivery AuthBloc', () {
    test('initial state is AuthInitial', () {
      expect(authBloc.state, equals(const AuthInitial()));
    });

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthAuthenticated] when login succeeds',
      build: () {
        when(() => mockAuthService.login('delivery@example.com', 'password123'))
            .thenAnswer((_) async => true);
        when(() => mockAuthService.isLoggedIn())
            .thenAnswer((_) async => true);
        when(() => mockAuthService.getCurrentUserRole())
            .thenReturn('DELIVERY');
        return authBloc;
      },
      act: (bloc) => bloc.add(const AuthLoginEvent(
        email: 'delivery@example.com',
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
        when(() => mockAuthService.login('delivery@example.com', 'wrong'))
            .thenThrow(Exception('Invalid credentials'));
        return authBloc;
      },
      act: (bloc) => bloc.add(const AuthLoginEvent(
        email: 'delivery@example.com',
        password: 'wrong',
      )),
      expect: () => [
        const AuthLoading(),
        isA<AuthError>(),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits AuthUnauthenticated when logout is requested',
      build: () {
        when(() => mockAuthService.logout())
            .thenAnswer((_) async => {});
        return authBloc;
      },
      act: (bloc) => bloc.add(const AuthLogoutEvent()),
      expect: () => [
        const AuthUnauthenticated(),
      ],
    );
  });
}

