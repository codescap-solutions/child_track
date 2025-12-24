import 'package:child_track/app/auth/view_model/auth_repository.dart';
import 'package:child_track/app/auth/view_model/bloc/auth_event.dart';
import 'package:child_track/app/auth/view_model/bloc/auth_state.dart';
import 'package:child_track/core/services/shared_prefs_service.dart';
import 'package:child_track/core/utils/app_logger.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;
  final SharedPrefsService _sharedPrefsService;
  AuthBloc({required AuthRepository authRepository, required SharedPrefsService sharedPrefsService})
      : _authRepository = authRepository,
        _sharedPrefsService = sharedPrefsService,
        super(AuthInitial()) {
    on<AuthStarted>(_onAuthStarted);
    on<SendOtp>(_onSendOtp);
    on<VerifyOtp>(_onVerifyOtp);
    on<RegisterUser>(_onRegisterUser);
    on<AuthLoggedIn>(_onAuthLoggedIn);
    on<AuthLoggedOut>(_onAuthLoggedOut);
  }

  void _onAuthStarted(AuthStarted event, Emitter<AuthState> emit) {
    emit(AuthLoading());
  }

  Future<void> _onSendOtp(
    SendOtp event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final response = await _authRepository.sendOtp(event.phoneNumber);
      if (response.isSuccess) {
        emit(AuthOtpSent(phoneNumber: event.phoneNumber));
      } else {
        emit(AuthError(message: response.message));
      }
    } catch (e) {
      AppLogger.error('Error sending OTP: ${e.toString()}');
      emit(AuthError(message: 'Failed to send OTP: ${e.toString()}'));
    }
  }

  Future<void> _onVerifyOtp(
    VerifyOtp event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final response = await _authRepository.verifyOtp(event.otp);
      if (response.isSuccess && response.data != null) {
        final data = response.data!;
        final isNewUser = data['is_new_user'] as bool? ?? false;
        final phoneNumber = data['phoneNumber'] as String?;
        final parentId = data['user']?['id'] as String?;
        final token = data['token'] as String?;
        
        // Save parent ID and token
        if (parentId != null) {
          await _sharedPrefsService.setString('parent_id', parentId);
          await _sharedPrefsService.setUserId(parentId);
        }
        if (token != null) {
          await _sharedPrefsService.setAuthToken(token);
        }

        // Check if this is a new user
        if (isNewUser && phoneNumber != null) {
          emit(AuthNewUser(phoneNumber: phoneNumber));
        } else if (response.data != null) {
          // Existing user - check if user has children
          final children = data['children'] as List<dynamic>?;
          final hasChildren = children != null && children.isNotEmpty;
          
          // If user has children, save the first child's ID
          if (hasChildren) {
            final firstChild = children[0] as Map<String, dynamic>?;
            final childId = firstChild?['child_id'] as String?;
            final childCode = firstChild?['child_code'] as String?;
            
            if (childId != null) {
              await _sharedPrefsService.setString('child_id', childId);
              AppLogger.info('OTP verification: Child ID saved: $childId');
            }
            if (childCode != null) {
              await _sharedPrefsService.setString('child_code', childCode);
            }
            // Save children count
            await _sharedPrefsService.setInt('children_count', children.length);
          }
          
          emit(AuthSuccess(hasChildren: hasChildren));
        } else {
          emit(AuthNeedsRegistration());
        }
      } else {
        emit(AuthError(message: response.message));
      }
    } catch (e) {
      AppLogger.error('Error verifying OTP: ${e.toString()}');
      emit(AuthError(message: 'Failed to verify OTP: ${e.toString()}'));
    }
  }

  Future<void> _onRegisterUser(
    RegisterUser event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final response = await _authRepository.registerUser(
        phoneNumber: event.phoneNumber,
        name: event.name,
        address: event.address,
      );
      if (response.isSuccess) {
        // After registration, user has no children yet
        emit(const AuthSuccess(hasChildren: false));
      } else {
        emit(AuthError(message: response.message));
      }
    } catch (e) {
      AppLogger.error('Error registering user: ${e.toString()}');
      emit(AuthError(message: 'Failed to register: ${e.toString()}'));
    }
  }

  void _onAuthLoggedIn(AuthLoggedIn event, Emitter<AuthState> emit) {
    emit(const AuthSuccess(hasChildren: false));
  }

  void _onAuthLoggedOut(AuthLoggedOut event, Emitter<AuthState> emit) {
    emit(AuthInitial());
  }
}
