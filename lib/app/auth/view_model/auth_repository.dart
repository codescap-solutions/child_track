import '../../../core/services/dio_client.dart';
import '../../../core/services/shared_prefs_service.dart';
import '../../../core/services/api_endpoints.dart';
import '../../../core/services/base_service.dart';

class AuthRepository extends BaseService {
  final SharedPrefsService _sharedPrefsService;

  AuthRepository({
    required DioClient dioClient,
    required SharedPrefsService sharedPrefsService,
  }) : _sharedPrefsService = sharedPrefsService,
       super(dioClient);

  // Send OTP
  Future<BaseResponse> sendOtp(String phoneNumber) async {
    try {
      final response = await post(
        ApiEndpoints.sendOtp,
        data: {'phoneNumber': phoneNumber},
      );

      if (response.isSuccess) {
        // Save phone number for OTP verification
        await _sharedPrefsService.setUserPhone(phoneNumber);
      }

      return response;
    } catch (e) {
      return BaseResponse.error(message: e.toString());
    }
  }

  // Verify OTP
  Future<BaseResponse> verifyOtp(String otp) async {
    try {
      final phoneNumber = _sharedPrefsService.getUserPhone();
      if (phoneNumber == null) {
        return BaseResponse.error(
          message: 'Phone number not found. Please try again.',
        );
      }

      final response = await post(
        ApiEndpoints.verifyOtp,
        data: {'phoneNumber': phoneNumber, 'otp': otp},
      );

      if (response.isSuccess && response.data != null) {
        // Save auth token and user ID
        // Handle different response structures
        final data = response.data!;
        final token = data['token'] as String?;
        final userId = data['user_id'] as String? ?? data['_id'] as String?;
        final name = data['name'] as String?;

        if (userId != null) {
          await _sharedPrefsService.setUserId(userId);
        }
        if (token != null) {
          await _sharedPrefsService.setAuthToken(token);
        }
        if (name != null) {
          // Optionally save user name if needed
        }
      }

      return response;
    } catch (e) {
      return BaseResponse.error(message: e.toString());
    }
  }

  // Refresh Token
  Future<BaseResponse> refreshToken() async {
    try {
      final response = await post(ApiEndpoints.refreshToken);

      if (response.isSuccess && response.data != null) {
        final token = response.data!['token'] as String?;
        if (token != null) {
          await _sharedPrefsService.setAuthToken(token);
        }
      }

      return response;
    } catch (e) {
      return BaseResponse.error(message: e.toString());
    }
  }

  // Logout
  Future<BaseResponse> logout() async {
    try {
      final response = await post(ApiEndpoints.logout);

      // Clear local storage regardless of API response
      await _sharedPrefsService.logout();

      return response;
    } catch (e) {
      // Clear local storage even if API call fails
      await _sharedPrefsService.logout();
      return BaseResponse.error(message: e.toString());
    }
  }

  // Check if user is logged in
  bool isLoggedIn() {
    return _sharedPrefsService.isLoggedIn();
  }

  // Get current user info
  Map<String, String?> getCurrentUser() {
    return {
      'user_id': _sharedPrefsService.getUserId(),
      'phone': _sharedPrefsService.getUserPhone(),
      'token': _sharedPrefsService.getAuthToken(),
    };
  }
}
