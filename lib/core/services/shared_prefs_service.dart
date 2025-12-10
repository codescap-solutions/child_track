import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_logger.dart';

class SharedPrefsService {
  static SharedPreferences? _prefs;

  // Initialize SharedPreferences
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    AppLogger.info('SharedPreferences initialized');
  }

  // Get SharedPreferences instance
  static SharedPreferences get prefs {
    if (_prefs == null) {
      throw Exception('SharedPreferences not initialized. Call init() first.');
    }
    return _prefs!;
  }

  // Auth Token
  Future<bool> setAuthToken(String token) async {
    try {
      return await prefs.setString('auth_token', token);
    } catch (e) {
      AppLogger.error('Error saving auth token: $e');
      return false;
    }
  }

  String? getAuthToken() {
    try {
      return prefs.getString('auth_token');
    } catch (e) {
      AppLogger.error('Error getting auth token: $e');
      return null;
    }
  }

  Future<bool> removeAuthToken() async {
    try {
      return await prefs.remove('auth_token');
    } catch (e) {
      AppLogger.error('Error removing auth token: $e');
      return false;
    }
  }

  // User ID
  Future<bool> setUserId(String userId) async {
    try {
      return await prefs.setString('user_id', userId);
    } catch (e) {
      AppLogger.error('Error saving user ID: $e');
      return false;
    }
  }

  String? getUserId() {
    try {
      return prefs.getString('user_id');
    } catch (e) {
      AppLogger.error('Error getting user ID: $e');
      return null;
    }
  }

  Future<bool> removeUserId() async {
    try {
      return await prefs.remove('user_id');
    } catch (e) {
      AppLogger.error('Error removing user ID: $e');
      return false;
    }
  }

  // User Phone Number
  Future<bool> setUserPhone(String phone) async {
    try {
      return await prefs.setString('user_phone', phone);
    } catch (e) {
      AppLogger.error('Error saving user phone: $e');
      return false;
    }
  }

  String? getUserPhone() {
    try {
      return prefs.getString('user_phone');
    } catch (e) {
      AppLogger.error('Error getting user phone: $e');
      return null;
    }
  }

  Future<bool> removeUserPhone() async {
    try {
      return await prefs.remove('user_phone');
    } catch (e) {
      AppLogger.error('Error removing user phone: $e');
      return false;
    }
  }

  // App Settings
  Future<bool> setBool(String key, bool value) async {
    try {
      return await prefs.setBool(key, value);
    } catch (e) {
      AppLogger.error('Error saving bool $key: $e');
      return false;
    }
  }

  bool getBool(String key, {bool defaultValue = false}) {
    try {
      return prefs.getBool(key) ?? defaultValue;
    } catch (e) {
      AppLogger.error('Error getting bool $key: $e');
      return defaultValue;
    }
  }

  Future<bool> setString(String key, String value) async {
    try {
      return await prefs.setString(key, value);
    } catch (e) {
      AppLogger.error('Error saving string $key: $e');
      return false;
    }
  }

  String? getString(String key) {
    try {
      return prefs.getString(key);
    } catch (e) {
      AppLogger.error('Error getting string $key: $e');
      return null;
    }
  }

  Future<bool> setInt(String key, int value) async {
    try {
      return await prefs.setInt(key, value);
    } catch (e) {
      AppLogger.error('Error saving int $key: $e');
      return false;
    }
  }

  int? getInt(String key) {
    try {
      return prefs.getInt(key);
    } catch (e) {
      AppLogger.error('Error getting int $key: $e');
      return null;
    }
  }

  // Clear all data
  Future<bool> clearAll() async {
    try {
      return await prefs.clear();
    } catch (e) {
      AppLogger.error('Error clearing all data: $e');
      return false;
    }
  }

  // Check if user is logged in
  bool isLoggedIn() {
    final token = getAuthToken();
    final userId = getUserId();
    return token != null &&
        token.isNotEmpty &&
        userId != null &&
        userId.isNotEmpty;
  }


  // Logout user
  Future<bool> logout() async {
    try {
      await removeAuthToken();
      await removeUserId();
      await removeUserPhone();
      await removeChildId();
      await removeParentId();
  
      await removeAuthToken();
      AppLogger.info('User logged out successfully');
      return true;
    } catch (e) {
      AppLogger.error('Error during logout: $e');
      return false;
    }
  }
  
   
  Future<bool> removeChildId() async {
    try {
      return await prefs.remove('child_id');
    } catch (e) {
      AppLogger.error('Error removing child ID: $e');
      return false;
    }
  }

  Future<bool> removeParentId() async {
    try {
      return await prefs.remove('parent_id');
    } catch (e) {
      AppLogger.error('Error removing parent ID: $e');
      return false;
    }
  }

}
