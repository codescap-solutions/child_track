import 'package:child_track/app/auth/view_model/auth_repository.dart';
import 'package:child_track/app/auth/view_model/bloc/auth_event.dart';
import 'package:child_track/app/auth/view_model/bloc/auth_state.dart';
import 'package:child_track/core/services/shared_prefs_service.dart';
import 'package:child_track/core/utils/app_logger.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;
  final SharedPrefsService _sharedPrefsService;
  AuthBloc({
    required AuthRepository authRepository,
    required SharedPrefsService sharedPrefsService,
  }) : _authRepository = authRepository,
       _sharedPrefsService = sharedPrefsService,
       super(AuthInitial()) {
    on<AuthStarted>(_onAuthStarted);
    on<SendOtp>(_onSendOtp);
    on<VerifyOtp>(_onVerifyOtp);
    on<SelectChild>(_onSelectChild);
    on<RegisterUser>(_onRegisterUser);
    on<AuthLoggedIn>(_onAuthLoggedIn);
    on<AuthLoggedOut>(_onAuthLoggedOut);
    AppLogger.info('AuthBloc initialized with SelectChild handler');
  }

  void _onAuthStarted(AuthStarted event, Emitter<AuthState> emit) {
    emit(AuthLoading());
  }

  Future<void> _onSendOtp(SendOtp event, Emitter<AuthState> emit) async {
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

  Future<void> _onVerifyOtp(VerifyOtp event, Emitter<AuthState> emit) async {
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

          if (hasChildren) {
            // Check how many children
            if (children.length > 1) {
              // Multiple children: Let user select
              // Parse children list properly
              final List<Map<String, dynamic>> parsedChildren = [];
              for (var child in children) {
                if (child is Map<String, dynamic>) {
                  parsedChildren.add(child);
                }
              }
              emit(AuthSelectChild(children: parsedChildren));
            } else {
              // Single child: Auto-select
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
              await _sharedPrefsService.setInt(
                'children_count',
                children.length,
              );
              emit(const AuthSuccess(hasChildren: true));
            }
          } else {
            // No children
            emit(const AuthSuccess(hasChildren: false));
          }
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

  Future<void> _onSelectChild(
    SelectChild event,
    Emitter<AuthState> emit,
  ) async {
    try {
      if (state is AuthSelectChild) {
        final currentState = state as AuthSelectChild;
        // Verify child exists in the list we have (optional security check)
        final selectedChild = currentState.children.firstWhere(
          (child) => child['child_id'] == event.childId,
          orElse: () => {},
        );

        if (selectedChild.isNotEmpty) {
          final childId = selectedChild['child_id'] as String;
          final childCode = selectedChild['child_code'] as String?;

          await _sharedPrefsService.setString('child_id', childId);
          if (childCode != null) {
            await _sharedPrefsService.setString('child_code', childCode);
          }
          await _sharedPrefsService.setInt(
            'children_count',
            currentState.children.length,
          );

          emit(const AuthSuccess(hasChildren: true));
        } else {
          emit(const AuthError(message: 'Selected child not found'));
        }
      }
    } catch (e) {
      AppLogger.error('Error selecting child: ${e.toString()}');
      emit(AuthError(message: 'Failed to select child: ${e.toString()}'));
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
