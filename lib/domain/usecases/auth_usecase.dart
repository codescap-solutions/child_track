import '../../data/repositories/auth_repository.dart';
import '../../core/services/base_service.dart';

class AuthUseCase {
  final AuthRepository _authRepository;

  AuthUseCase({required AuthRepository authRepository})
    : _authRepository = authRepository;

  // Send OTP
  Future<BaseResponse<Map<String, dynamic>>> sendOtp(String phoneNumber) async {
    // Validate phone number
    if (phoneNumber.isEmpty) {
      return BaseResponse.error(message: 'Phone number is required');
    }

    if (phoneNumber.length < 10) {
      return BaseResponse.error(message: 'Please enter a valid phone number');
    }

    return await _authRepository.sendOtp(phoneNumber);
  }

  // Verify OTP
  Future<BaseResponse<Map<String, dynamic>>> verifyOtp(String otp) async {
    // Validate OTP
    if (otp.isEmpty) {
      return BaseResponse.error(message: 'OTP is required');
    }

    if (otp.length != 6) {
      return BaseResponse.error(message: 'Please enter a valid 6-digit OTP');
    }

    return await _authRepository.verifyOtp(otp);
  }

  // Refresh Token
  Future<BaseResponse<Map<String, dynamic>>> refreshToken() async {
    return await _authRepository.refreshToken();
  }

  // Logout
  Future<BaseResponse<bool>> logout() async {
    return await _authRepository.logout();
  }

  // Check if user is logged in
  bool isLoggedIn() {
    return _authRepository.isLoggedIn();
  }

  // Get current user info
  Map<String, String?> getCurrentUser() {
    return _authRepository.getCurrentUser();
  }
}
