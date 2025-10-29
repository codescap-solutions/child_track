import 'package:flutter/foundation.dart';
import '../data/repositories/auth_repository.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthRepository _authRepository;

  AuthViewModel({required AuthRepository authRepository})
      : _authRepository = authRepository;

  // Loading states
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Error state
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // Success states
  String? _successMessage;
  String? get successMessage => _successMessage;

  // User data
  Map<String, dynamic>? _userData;
  Map<String, dynamic>? get userData => _userData;

  // Private method to set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Private method to set error
  void _setError(String? error) {
    _errorMessage = error;
    _successMessage = null;
    notifyListeners();
  }

  // Private method to set success
  void _setSuccess(String? message, [Map<String, dynamic>? data]) {
    _successMessage = message;
    _errorMessage = null;
    _userData = data;
    notifyListeners();
  }

  // Clear messages
  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  // Send OTP
  Future<bool> sendOtp(String phoneNumber) async {
    _setLoading(true);
    _setError(null);

    try {
      // Validate phone number
      if (phoneNumber.isEmpty) {
        _setError('Phone number is required');
        return false;
      }

      if (phoneNumber.length < 10) {
        _setError('Please enter a valid phone number');
        return false;
      }

      final response = await _authRepository.sendOtp(phoneNumber);

      if (response.isSuccess) {
        _setSuccess(response.message);
        return true;
      } else {
        _setError(response.message);
        return false;
      }
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Verify OTP
  Future<bool> verifyOtp(String otp) async {
    _setLoading(true);
    _setError(null);

    try {
      // Validate OTP
      if (otp.isEmpty) {
        _setError('OTP is required');
        return false;
      }

      if (otp.length != 6) {
        _setError('Please enter a valid 6-digit OTP');
        return false;
      }

      final response = await _authRepository.verifyOtp(otp);

      if (response.isSuccess) {
        _setSuccess(response.message, response.data);
        return true;
      } else {
        _setError(response.message);
        return false;
      }
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Refresh Token
  Future<bool> refreshToken() async {
    _setLoading(true);
    _setError(null);

    try {
      final response = await _authRepository.refreshToken();

      if (response.isSuccess) {
        _setSuccess('Token refreshed successfully', response.data);
        return true;
      } else {
        _setError(response.message);
        return false;
      }
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Logout
  Future<bool> logout() async {
    _setLoading(true);
    _setError(null);

    try {
      final response = await _authRepository.logout();

      if (response.isSuccess) {
        _setSuccess('Logged out successfully');
        _userData = null;
        return true;
      } else {
        _setError(response.message);
        return false;
      }
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Check if user is logged in
  bool isLoggedIn() {
    return _authRepository.isLoggedIn();
  }

  // Get current user info
  Map<String, String?> getCurrentUser() {
    return _authRepository.getCurrentUser();
  }

  // Check auth status and update user data
  void checkAuthStatus() {
    try {
      final isLoggedIn = _authRepository.isLoggedIn();

      if (isLoggedIn) {
        final userData = _authRepository.getCurrentUser();
        _userData = userData;
        _setSuccess('User already logged in', userData);
      } else {
        _userData = null;
        _setError(null);
      }
    } catch (e) {
      _setError(e.toString());
    }
  }

}
