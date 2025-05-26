import 'package:bloc/bloc.dart';
import 'package:domain/domain.dart';
import 'package:equatable/equatable.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;

  AuthBloc({required this.authRepository}) : super(AuthInitial()) {
    on<AuthCheckStatusEvent>(_onAuthCheckStatus);
    on<AuthLoginEvent>(_onAuthLogin);
    on<AuthSignupEvent>(_onAuthSignup);
    on<AuthLogoutEvent>(_onAuthLogout);
    on<AuthForgotPasswordEvent>(_onAuthForgotPassword);
    on<AuthUpdateProfileEvent>(_onAuthUpdateProfile);
    on<AuthChangePasswordEvent>(_onAuthChangePassword);
  }

  Future<void> _onAuthCheckStatus(
    AuthCheckStatusEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    
    final result = await authRepository.getCurrentUser();
    
    await result.fold(
      (failure) async {
        emit(AuthUnauthenticated());
      },
      (user) async {
        if (user != null) {
          emit(AuthAuthenticated(user));
        } else {
          emit(AuthUnauthenticated());
        }
      },
    );
  }

  Future<void> _onAuthLogin(
    AuthLoginEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    
    final result = await authRepository.signInWithEmailAndPassword(
      email: event.email,
      password: event.password,
    );
    
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (user) => emit(AuthAuthenticated(user)),
    );
  }

  Future<void> _onAuthSignup(
    AuthSignupEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    
    final result = await authRepository.signUpWithEmailAndPassword(
      email: event.email,
      password: event.password,
      name: event.name,
      role: UserRole.customer, // Always register as customer in user app
      phone: event.phone,
    );
    
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (user) => emit(AuthAuthenticated(user)),
    );
  }

  Future<void> _onAuthLogout(
    AuthLogoutEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    
    final result = await authRepository.signOut();
    
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (_) => emit(AuthUnauthenticated()),
    );
  }

  Future<void> _onAuthForgotPassword(
    AuthForgotPasswordEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    
    final result = await authRepository.sendPasswordResetEmail(
      email: event.email,
    );
    
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (_) => emit(AuthPasswordResetSent()),
    );
  }

  Future<void> _onAuthUpdateProfile(
    AuthUpdateProfileEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    
    final result = await authRepository.updateProfile(
      name: event.name,
      phone: event.phone,
      profilePicture: event.profilePicture,
    );
    
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (user) => emit(AuthAuthenticated(user)),
    );
  }

  Future<void> _onAuthChangePassword(
    AuthChangePasswordEvent event,
    Emitter<AuthState> emit,
  ) async {
    final currentState = state;
    
    if (currentState is AuthAuthenticated) {
      emit(AuthLoading());
      
      final result = await authRepository.changePassword(
        currentPassword: event.currentPassword,
        newPassword: event.newPassword,
      );
      
      result.fold(
        (failure) => emit(AuthError(failure.message)),
        (_) => emit(AuthPasswordChanged(currentState.user)),
      );
    }
  }
}