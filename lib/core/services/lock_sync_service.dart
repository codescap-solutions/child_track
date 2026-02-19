import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:child_track/core/navigation/route_names.dart';
import 'package:child_track/core/utils/app_logger.dart';

class LockSyncService {
  static final LockSyncService _instance = LockSyncService._internal();
  factory LockSyncService() => _instance;
  LockSyncService._internal();

  static const MethodChannel _channel = MethodChannel(
    'com.truenyx.naviq/device_info',
  );

  GlobalKey<NavigatorState>? _navigatorKey;

  void initialize(GlobalKey<NavigatorState> navigatorKey) {
    _navigatorKey = navigatorKey;
    _channel.setMethodCallHandler(_handleMethodCall);
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'appBlocked':
        final String? packageName = call.arguments as String?;
        if (packageName != null && _navigatorKey?.currentState != null) {
          _navigatorKey!.currentState!.pushNamed(
            RouteNames.appBlocked,
            arguments: packageName,
          );
        }
        break;
      default:
        // Handle other methods if needed
        break;
    }
  }

  /// Pushes the list of locked packages to the native AppLockService.
  /// The native service will immediately start blocking these apps.
  Future<bool> syncLockedAppsToNative(List<String> packages) async {
    if (!Platform.isAndroid) return false;
    try {
      final result = await _channel.invokeMethod<bool>(
        'updateLockList',
        packages,
      );
      AppLogger.info(
        'Synced ${packages.length} locked apps to native: $result',
      );
      return result ?? false;
    } catch (e) {
      AppLogger.error('Error syncing locked apps to native: $e');
      return false;
    }
  }

  /// Checks if the Accessibility Service (AppLockService) is enabled.
  Future<bool> checkAccessibilityPermission() async {
    if (!Platform.isAndroid) return false;
    try {
      final isEnabled = await _channel.invokeMethod<bool>(
        'checkAccessibilityPermission',
      );
      return isEnabled ?? false;
    } catch (e) {
      AppLogger.error('Error checking accessibility permission: $e');
      return false;
    }
  }

  /// Opens the Android Accessibility Settings page so the user can enable the service.
  Future<bool> openAccessibilitySettings() async {
    if (!Platform.isAndroid) return false;
    try {
      final result = await _channel.invokeMethod<bool>(
        'openAccessibilitySettings',
      );
      return result ?? false;
    } catch (e) {
      AppLogger.error('Error opening accessibility settings: $e');
      return false;
    }
  }
}
