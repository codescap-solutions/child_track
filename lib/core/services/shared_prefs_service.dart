import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/child_profile.dart';
import '../utils/app_logger.dart';

class SharedPrefsService {
  static SharedPreferences? _prefs;

  // Initialize SharedPreferences
  static final _secureStorage = FlutterSecureStorage();
  static String? _cachedAuthToken;
  static String? _cachedRefreshToken;

  // Initialize SharedPreferences and load secure token
  // Initialize SharedPreferences and load secure token
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();

    // Migration: Check for legacy token in SharedPreferences
    // We only migrate IF SecureStorage works. If it fails, we stick to Prefs.
    String? secureToken;
    bool secureStorageWorking = true;

    try {
      secureToken = await _secureStorage.read(key: 'auth_token');
    } catch (e) {
      secureStorageWorking = false;
      AppLogger.error('SecureStorage not available: $e');
    }

    final legacyToken = _prefs?.getString('auth_token');

    if (secureStorageWorking &&
        legacyToken != null &&
        legacyToken.isNotEmpty &&
        secureToken == null) {
      // Migrate
      AppLogger.info('Migrating legacy auth token to SecureStorage');
      try {
        await _secureStorage.write(key: 'auth_token', value: legacyToken);
        _cachedAuthToken = legacyToken;
        await _prefs?.remove('auth_token');
      } catch (e) {
        // If write fails, keep legacy
        _cachedAuthToken = legacyToken;
      }
    } else {
      // Load from whichever source is available
      _cachedAuthToken = secureToken ?? legacyToken;
    }

    // Load refresh token if secure storage is working
    if (secureStorageWorking) {
      try {
        _cachedRefreshToken = await _secureStorage.read(key: 'refresh_token');
      } catch (e) {
        AppLogger.error('Error reading refresh token from secure storage: $e');
      }
    }

    AppLogger.info(
      'SharedPreferences and SecureStorage initialized. Token loaded: ${_cachedAuthToken != null}',
    );
  }

  // Get SharedPreferences instance
  static SharedPreferences get prefs {
    if (_prefs == null) {
      throw Exception('SharedPreferences not initialized. Call init() first.');
    }
    return _prefs!;
  }

  // Auth Token (Secure)
  // Auth Token (Secure with Fallback)
  Future<bool> setAuthToken(String token) async {
    try {
      await _secureStorage.write(key: 'auth_token', value: token);
      _cachedAuthToken = token;
      return true;
    } catch (e) {
      AppLogger.error('Error saving auth token to secure storage: $e');
      // Fallback to SharedPreferences
      try {
        await prefs.setString('auth_token', token);
        _cachedAuthToken = token;
        return true;
      } catch (e2) {
        AppLogger.error('Error saving auth token to shared prefs: $e2');
        return false;
      }
    }
  }

  // Force reload of token from storage (useful after migration/re-install)
  Future<void> reloadAuthToken() async {
    try {
      _cachedAuthToken = await _secureStorage.read(key: 'auth_token');
    } catch (e) {
      AppLogger.error('Error reloading secure token: $e');
      // Fallback to SharedPreferences
      try {
        _cachedAuthToken = prefs.getString('auth_token');
      } catch (e2) {
        AppLogger.error('Error reloading shared prefs token: $e2');
      }
    }
    AppLogger.info('Auth token reloaded: ${_cachedAuthToken != null}');
  }

  String? getAuthToken() {
    return _cachedAuthToken;
  }

  Future<bool> removeAuthToken() async {
    try {
      await _secureStorage.delete(key: 'auth_token');
      _cachedAuthToken = null;
      return true;
    } catch (e) {
      AppLogger.error('Error removing auth token: $e');
      return false;
    }
  }

  // Refresh Token
  Future<bool> setRefreshToken(String token) async {
    try {
      await _secureStorage.write(key: 'refresh_token', value: token);
      _cachedRefreshToken = token;
      return true;
    } catch (e) {
      AppLogger.error('Error saving refresh token: $e');
      return false;
    }
  }

  Future<void> reloadRefreshToken() async {
    try {
      _cachedRefreshToken = await _secureStorage.read(key: 'refresh_token');
    } catch (e) {
      AppLogger.error('Error reloading refresh token: $e');
    }
  }

  String? getRefreshToken() {
    return _cachedRefreshToken;
  }

  Future<bool> removeRefreshToken() async {
    try {
      await _secureStorage.delete(key: 'refresh_token');
      _cachedRefreshToken = null;
      return true;
    } catch (e) {
      AppLogger.error('Error removing refresh token: $e');
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

  // Check if logged in user is a Parent
  bool get isParent {
    final parentId = getString('parent_id');
    return parentId != null && parentId.isNotEmpty;
  }

  bool get isPrimaryParent {
    return getBool('is_primary_parent', defaultValue: true);
  }

  // Logout user
  Future<bool> logout() async {
    try {
      await removeAuthToken();
      await removeRefreshToken();
      await removeUserId();
      await removeUserPhone();
      await removeChildId();
      await removeParentId();

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

  // Multi-Child Support
  Future<bool> saveChildren(List<ChildProfile> children) async {
    try {
      final String encoded = json.encode(
        children.map((e) => e.toMap()).toList(),
      );
      return await prefs.setString('stored_children', encoded);
    } catch (e) {
      AppLogger.error('Error saving children list: $e');
      return false;
    }
  }

  List<ChildProfile> getChildren() {
    try {
      final String? encoded = prefs.getString('stored_children');
      if (encoded == null) return [];
      final List<dynamic> decoded = json.decode(encoded);
      return decoded.map((e) => ChildProfile.fromMap(e)).toList();
    } catch (e) {
      AppLogger.error('Error getting children list: $e');
      return [];
    }
  }

  Future<bool> addChild(ChildProfile child) async {
    final children = getChildren();
    // Prevent duplicates
    children.removeWhere((element) => element.childId == child.childId);
    children.add(child);
    return await saveChildren(children);
  }

  Future<bool> switchChild(String childId) async {
    final children = getChildren();
    final child = children.firstWhere(
      (element) => element.childId == childId,
      orElse: () => throw Exception('Child not found locally'),
    );

    // Update session data
    await setAuthToken(child.authToken);
    await setString('child_code', child.childCode);
    await setString('child_id', child.childId); // Critical for Home module
    await setUserId(
      child.childId,
    ); // Assuming userId maps to childId in this app context
    await setString('child_name', child.childName);

    // Update last active
    final updatedChildren = children.map((e) {
      if (e.childId == childId) {
        return e.copyWith(lastActiveAt: DateTime.now());
      }
      return e;
    }).toList();
    await saveChildren(updatedChildren);

    return true;
  }

  // Get all notifications
  List<Map<String, dynamic>> getNotifications() {
    try {
      final String? encoded = prefs.getString('stored_notifications');
      if (encoded == null) return [];
      final List<dynamic> decoded = json.decode(encoded);
      return List<Map<String, dynamic>>.from(decoded);
    } catch (e) {
      AppLogger.error('Error getting notifications list: $e');
      return [];
    }
  }

  // Save list of notifications
  Future<bool> saveNotifications(List<Map<String, dynamic>> list) async {
    try {
      final String encoded = json.encode(list);
      return await prefs.setString('stored_notifications', encoded);
    } catch (e) {
      AppLogger.error('Error saving notifications list: $e');
      return false;
    }
  }

  // Add a single notification
  Future<bool> addNotification(Map<String, dynamic> notification) async {
    final list = getNotifications();
    list.insert(0, notification); // Insert at beginning so newest is first
    // Limit to last 100 notifications to prevent storage bloat
    if (list.length > 100) {
      list.removeRange(100, list.length);
    }
    return await saveNotifications(list);
  }

  // Clear notifications
  Future<bool> clearNotifications() async {
    try {
      return await prefs.remove('stored_notifications');
    } catch (e) {
      AppLogger.error('Error clearing notifications: $e');
      return false;
    }
  }

  // Deletion Restriction Settings
  Future<bool> setAllowDelete(bool value) async {
    return await setBool('is_allow_delete', value);
  }

  bool getAllowDelete({bool defaultValue = true}) {
    return getBool('is_allow_delete', defaultValue: defaultValue);
  }
}
