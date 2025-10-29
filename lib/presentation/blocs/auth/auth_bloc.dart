import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/usecases/auth_usecase.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthUseCase _authUseCase;

  AuthBloc({required AuthUseCase authUseCase})
    : _authUseCase = authUseCase,
      super(const AuthInitial()) {
    on<SendOtpEvent>(_onSendOtp);
    on<VerifyOtpEvent>(_onVerifyOtp);
    on<LogoutEvent>(_onLogout);
    on<CheckAuthStatusEvent>(_onCheckAuthStatus);
    on<RefreshTokenEvent>(_onRefreshToken);
  }

  Future<void> _onSendOtp(SendOtpEvent event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());

    try {
      final response = await _authUseCase.sendOtp(event.phoneNumber);

      if (response.isSuccess) {
        emit(OtpSentSuccess(message: response.message));
      } else {
        emit(AuthFailure(message: response.message));
      }
    } catch (e) {
      emit(AuthFailure(message: e.toString()));
    }
  }

  Future<void> _onVerifyOtp(
    VerifyOtpEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    try {
      final response = await _authUseCase.verifyOtp(event.otp);

      if (response.isSuccess) {
        emit(
          OtpVerifiedSuccess(
            message: response.message,
            userData: response.data,
          ),
        );
      } else {
        emit(AuthFailure(message: response.message));
      }
    } catch (e) {
      emit(AuthFailure(message: e.toString()));
    }
  }

  Future<void> _onLogout(LogoutEvent event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());

    try {
      final response = await _authUseCase.logout();

      if (response.isSuccess) {
        emit(const LogoutSuccess());
      } else {
        emit(AuthFailure(message: response.message));
      }
    } catch (e) {
      emit(AuthFailure(message: e.toString()));
    }
  }

  Future<void> _onCheckAuthStatus(
    CheckAuthStatusEvent event,
    Emitter<AuthState> emit,
  ) async {
    try {
      final isLoggedIn = _authUseCase.isLoggedIn();

      if (isLoggedIn) {
        final userData = _authUseCase.getCurrentUser();
        emit(
          OtpVerifiedSuccess(
            message: 'User already logged in',
            userData: userData,
          ),
        );
      } else {
        emit(const AuthInitial());
      }
    } catch (e) {
      emit(AuthFailure(message: e.toString()));
    }
  }

  Future<void> _onRefreshToken(
    RefreshTokenEvent event,
    Emitter<AuthState> emit,
  ) async {
    try {
      final response = await _authUseCase.refreshToken();

      if (response.isSuccess) {
        emit(
          AuthSuccess(
            message: 'Token refreshed successfully',
            data: response.data,
          ),
        );
      } else {
        emit(AuthFailure(message: response.message));
      }
    } catch (e) {
      emit(AuthFailure(message: e.toString()));
    }
  }
}
