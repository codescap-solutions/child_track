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
        final data = response.data!;
        final isNewUser = data['is_new_user'] as bool? ?? false;
        final phoneNumber = data['phoneNumber'] as String?;
        
        // Save phone number if provided
        if (phoneNumber != null) {
          await _sharedPrefsService.setUserPhone(phoneNumber);
        }
        
        // If new user, don't save auth data yet (will be saved after registration)
        if (!isNewUser) {
          // Save auth token and user ID (parent ID)
          // Handle different response structures
          final token = data['token'] as String?;
          final parentId = data['user_id'] as String? ?? data['_id'] as String?;
          final name = data['name'] as String?;
          final children = data['children'] as List<dynamic>?;

          if (parentId != null) {
            await _sharedPrefsService.setUserId(parentId);
            // Also save as parent_id for clarity
            await _sharedPrefsService.setString('parent_id', parentId);
          }
          if (token != null) {
            await _sharedPrefsService.setAuthToken(token);
          }
          if (name != null) {
            await _sharedPrefsService.setString('parent_name', name);
          }
          // Save children count for checking if child is connected
          if (children != null) {
            await _sharedPrefsService.setInt('children_count', children.length);
            // If there's at least one child, save the first child ID
            // Children can be array of strings (IDs) or array of objects
            if (children.isNotEmpty) {
              String? childId;
              if (children[0] is String) {
                // Array of IDs: ["693721db9026941d7fc780df"]
                childId = children[0] as String;
              } else if (children[0] is Map) {
                // Array of objects: [{"_id": "...", ...}]
                final firstChild = children[0] as Map<String, dynamic>;
                childId = firstChild['_id'] as String? ?? firstChild['id'] as String?;
              }
              // if (childId != null) {
              //   await _sharedPrefsService.setString('child_id', childId);
              // }
            }
          }
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

  // Register User
  Future<BaseResponse> registerUser({
    required String phoneNumber,
    required String name,
    Map<String, dynamic>? address,
  }) async {
    try {
      final data = <String, dynamic>{
        'phoneNumber': phoneNumber,
        'name': name,
      };
      
      if (address != null) {
        data['address'] = address;
      }

      final response = await post(
        ApiEndpoints.registerUser,
        data: data,
      );

      if (response.isSuccess && response.data != null) {
        // Save auth token and user ID (parent ID) after registration
        final responseData = response.data!;
        final token = responseData['token'] as String?;
        final parentId = responseData['user_id'] as String? ?? responseData['_id'] as String?;
        final savedName = responseData['name'] as String?;

        if (parentId != null) {
          await _sharedPrefsService.setUserId(parentId);
          await _sharedPrefsService.setString('parent_id', parentId);
        }
        if (token != null) {
          await _sharedPrefsService.setAuthToken(token);
        }
        if (savedName != null) {
          await _sharedPrefsService.setString('parent_name', savedName);
        }
        // New user has no children initially
        await _sharedPrefsService.setInt('children_count', 0);
      }

      return response;
    } catch (e) {
      return BaseResponse.error(message: e.toString());
    }
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
