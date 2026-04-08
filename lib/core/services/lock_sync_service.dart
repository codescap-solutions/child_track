import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:child_track/app/social_apps/view_model/app_lock_repository.dart';
import 'package:child_track/core/di/injector.dart';
import 'package:child_track/core/navigation/route_names.dart';
import 'package:child_track/core/utils/app_logger.dart';

class LockSyncService {
  static final LockSyncService _instance = LockSyncService._internal();
  factory LockSyncService() => _instance;
  LockSyncService._internal();

  static const MethodChannel _channel = MethodChannel(
    'com.truenyx.naviq/device_info',
  );

  /// Separate channel dedicated to receiving lock events from native.
  static const MethodChannel _lockEventChannel = MethodChannel(
    'com.truenyx.naviq/app_lock_events',
  );

  GlobalKey<NavigatorState>? _navigatorKey;

  /// Holds a blocked package that arrived before the navigator was ready.
  String? _pendingBlockedPackage;

  void initialize(GlobalKey<NavigatorState> navigatorKey) {
    _navigatorKey = navigatorKey;
    _lockEventChannel.setMethodCallHandler(_handleMethodCall);
    AppLogger.info('LockSyncService: initialized with lock event channel');
  }

  /// Call this after the initial route is settled (e.g. after SplashScreen
  /// navigates to SosView) to flush any block event that arrived too early.
  void navigateIfPending() {
    if (_pendingBlockedPackage != null) {
      final pkg = _pendingBlockedPackage!;
      _pendingBlockedPackage = null;
      AppLogger.info('LockSyncService: flushing pending appBlocked for $pkg');
      _pushAppBlocked(pkg);
    }
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    AppLogger.info(
      'LockSyncService: Received method call: ${call.method}, args: ${call.arguments}',
    );
    switch (call.method) {
      case 'appBlocked':
        final String? packageName = call.arguments as String?;
        AppLogger.info(
          'LockSyncService: appBlocked event, package=$packageName, navigatorReady=${_navigatorKey?.currentState != null}',
        );
        if (packageName != null) {
          if (_navigatorKey?.currentState != null) {
            _pushAppBlocked(packageName);
          } else {
            // Navigator not ready yet (cold launch) — buffer and retry later.
            _pendingBlockedPackage = packageName;
            AppLogger.info(
              'LockSyncService: navigator not ready, buffering block for $packageName',
            );
          }
        }
        break;
      case 'clearBlockScreen':
        AppLogger.info('LockSyncService: clearBlockScreen event received');
        _pendingBlockedPackage = null;
        final nav = _navigatorKey?.currentState;
        if (nav != null) {
          // If we are currently on the appBlocked route, pop it.
          // Because pushNamedAndRemoveUntil was used, popping it will
          // return to the root route (SosView).
          nav.popUntil((route) => route.isFirst);
          AppLogger.info('LockSyncService: Popped to root route');
        }
        break;
      default:
        break;
    }
  }

  void _pushAppBlocked(String packageName) {
    AppLogger.info(
      '>>> LockSyncService: _pushAppBlocked called for $packageName',
    );

    final nav = _navigatorKey?.currentState;
    if (nav == null) {
      AppLogger.error('>>> LockSyncService: Navigator state is NULL, cannot navigate');
      _pendingBlockedPackage = packageName;
      return;
    }

    // Use pushNamedAndRemoveUntil to clear any existing AppBlockedScreen
    // before pushing a new one. This prevents stacking multiple block screens.
    // We keep the base route (SosView) and remove everything above it.
    nav.pushNamedAndRemoveUntil(
      RouteNames.appBlocked,
      (route) => route.isFirst,  // Keep only the base route (SosView)
      arguments: {'packageName': packageName, 'appName': null},
    );
    AppLogger.info(
      '>>> LockSyncService: Navigated to AppBlockedScreen for $packageName',
    );
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

  /// Fetches locked apps from the child API endpoint and syncs them
  /// to the native AppLockService. Call this on child app startup
  /// and when receiving SYNC_LOCKED_APPS FCM push.
  Future<void> fetchAndSyncLockedApps() async {
    if (!Platform.isAndroid) return;
    try {
      final repo = injector<AppLockRepository>();
      final response = await repo.getChildLockedApps();

      if (response.isSuccess && response.data != null) {
        final packages = response.data!.lockedPackages
            .map((e) => e.packageName)
            .toList();
        await syncLockedAppsToNative(packages);
        AppLogger.info(
          'Child lock sync complete: ${packages.length} apps locked',
        );
      } else {
        AppLogger.error(
          'Failed to fetch child locked apps: ${response.message}',
        );
      }
    } catch (e) {
      AppLogger.error('Error in fetchAndSyncLockedApps: $e');
    }
  }
}
