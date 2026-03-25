import 'package:child_track/app/childapp/model/scree_time_model.dart';
import 'package:child_track/app/childapp/view_model/repository/child_repo.dart';
import 'package:child_track/app/childapp/view_model/repository/device_info_service.dart';
import 'package:child_track/core/services/shared_prefs_service.dart';
import 'package:child_track/core/utils/app_logger.dart';

class ScreenTimeSyncService {
  final ChildInfoService _deviceInfoService;
  final ChildRepo _childRepo;
  final SharedPrefsService _prefs;

  // Cache for screen time data to avoid frequent re-fetching
  List<AppScreenTimeModel>? _screenTimeCache;
  DateTime? _lastFetchTime;
  static const Duration _cacheDuration = Duration(minutes: 5);

  ScreenTimeSyncService(this._deviceInfoService, this._childRepo, this._prefs);

  /// Check if cache is still valid
  bool _isCacheValid() {
    if (_screenTimeCache == null || _lastFetchTime == null) return false;
    return DateTime.now().difference(_lastFetchTime!).inMinutes <
        _cacheDuration.inMinutes;
  }

  Future<void> syncScreenTime() async {
    final childId = _prefs.getString('child_id');
    if (childId == null || childId.isEmpty) {
      AppLogger.warning('ScreenTimeSyncService: child_id is null or empty');
      return;
    }

    // Permission check - cache result for 1 minute to avoid frequent native calls
    final hasPermissionKey = 'usage_permission_cache';
    final lastPermissionCheck = _prefs.getString('${hasPermissionKey}_time');
    bool hasPermission = false;

    if (lastPermissionCheck != null) {
      final lastCheck = DateTime.parse(lastPermissionCheck);
      if (DateTime.now().difference(lastCheck).inMinutes < 1) {
        hasPermission = _prefs.getBool(hasPermissionKey);
        if (!hasPermission) {
          AppLogger.warning(
            'ScreenTimeSyncService: Usage permission not granted (cached)',
          );
          return;
        } else {
          // Cache is valid and permission is granted, proceed with sync
          try {
            final mergedScreenTime = await fetchScreenTimeData();
            if (mergedScreenTime.isEmpty) {
              AppLogger.info(
                'ScreenTimeSyncService: No apps with usage > 0 found.',
              );
              return;
            }

            await uploadScreenTimeData(mergedScreenTime, childId);
            await _syncDeviceInfo(childId);
            await _syncAppIcons(mergedScreenTime);

            // Save sync time
            _prefs.setString(
              'last_screen_time_sync',
              DateTime.now().toIso8601String(),
            );
            return;
          } catch (e) {
            AppLogger.error(
              'ScreenTimeSyncService: Failed to sync screen time: $e',
            );
            return;
          }
        }
      }
    }

    // Fresh permission check if cache expired or not set
    hasPermission = await _deviceInfoService.checkUsagePermission();
    _prefs.setBool(hasPermissionKey, hasPermission);
    _prefs.setString(
      '${hasPermissionKey}_time',
      DateTime.now().toIso8601String(),
    );

    if (!hasPermission) {
      AppLogger.warning('ScreenTimeSyncService: Usage permission not granted');
      return;
    }

    try {
      final mergedScreenTime = await fetchScreenTimeData();
      if (mergedScreenTime.isEmpty) {
        AppLogger.info('ScreenTimeSyncService: No apps with usage > 0 found.');
        return;
      }

      await uploadScreenTimeData(mergedScreenTime, childId);
      await _syncDeviceInfo(childId);
      await _syncAppIcons(mergedScreenTime);

      // Save sync time
      _prefs.setString(
        'last_screen_time_sync',
        DateTime.now().toIso8601String(),
      );
    } catch (e) {
      AppLogger.error('ScreenTimeSyncService: Failed to sync screen time: $e');
    }
  }

  Future<List<AppScreenTimeModel>> fetchScreenTimeData() async {
    // Return cached data if valid
    if (_isCacheValid()) {
      AppLogger.info(
        'ScreenTimeSyncService: Returning cached screen time data',
      );
      return _screenTimeCache ?? [];
    }

    final installedApps = await _deviceInfoService.getInstalledApps();
    final screenTimeUsage = await _deviceInfoService.getScreenTime();

    // Popular system apps allowlist — these are system apps we still
    // want to include in screen time reports to the parent.
    final allowList = {
      // Google apps
      'com.google.android.youtube', // YouTube
      'com.google.android.googlequicksearchbox', // Google Search
      'com.android.chrome', // Chrome
      'com.google.android.gm', // Gmail
      'com.google.android.apps.maps', // Maps
      'com.google.android.apps.photos', // Google Photos
      'com.google.android.apps.docs', // Google Drive
      'com.google.android.apps.nbu.files', // Files by Google
      'com.google.android.dialer', // Phone
      'com.google.android.apps.messaging', // Messages
      'com.google.android.deskclock', // Clock
      'com.google.android.calendar', // Google Calendar
      'com.google.android.gms', // Google Play Services
      'com.android.vending', // Google Play Store
      // Social & messaging
      'com.facebook.katana', // Facebook
      'com.instagram.android', // Instagram
      'com.whatsapp', // WhatsApp
      'com.whatsapp.w4b', // WhatsApp Business
      'com.snapchat.android', // Snapchat
      'com.zhiliaoapp.musically', // TikTok
      'org.telegram.messenger', // Telegram
      'com.twitter.android', // Twitter/X
      // Entertainment
      'com.spotify.music', // Spotify
      'com.netflix.mediaclient', // Netflix
      'in.startv.hotstar', // JioHotstar
      'com.amazon.avod.thirdpartyclient', // Amazon Prime Video
    };

    // Create a map of usage data for quick lookup
    final usageMap = {for (var app in screenTimeUsage) app.package: app};

    // Merge installed apps with usage data
    final List<AppScreenTimeModel> mergedScreenTime = [];

    for (var app in installedApps) {
      bool shouldInclude =
          !app.isSystemApp || allowList.contains(app.packageName);

      if (shouldInclude) {
        final usageModel = usageMap[app.packageName];
        final seconds = usageModel?.seconds ?? 0;
        final lastTimeUsed = usageModel?.lastTimeUsed ?? 0;

        if (seconds > 0) {
          mergedScreenTime.add(
            AppScreenTimeModel(
              package: app.packageName,
              appName: app.appName,
              isSystemApp: app.isSystemApp,
              seconds: seconds,
              lastTimeUsed: lastTimeUsed,
              iconBase64: usageModel?.iconBase64,
            ),
          );
        }
      }
      usageMap.remove(app.packageName);
    }

    // Add remaining apps from usageMap that weren't in installed apps
    usageMap.forEach((package, usageModel) {
      if (usageModel.seconds > 0) {
        mergedScreenTime.add(
          usageModel.copyWith(
            appName: usageModel.appName.isNotEmpty
                ? usageModel.appName
                : package,
          ),
        );
      }
    });

    // Sort by seconds and cache
    mergedScreenTime.sort((a, b) => b.seconds.compareTo(a.seconds));
    _screenTimeCache = mergedScreenTime;
    _lastFetchTime = DateTime.now();

    return mergedScreenTime;
  }

  Future<void> uploadScreenTimeData(
    List<AppScreenTimeModel> mergedScreenTime,
    String childId,
  ) async {
    final appsData = mergedScreenTime.map((app) {
      return {
        "packageName": app.package,
        "usageTime": app.seconds,
        "appName": app.appName,
      };
    }).toList();

    // Ensure timestamp is at midnight UTC of current day as per docs
    final now = DateTime.now().toUtc();
    final dateString = DateTime.utc(
      now.year,
      now.month,
      now.day,
    ).toIso8601String();

    final requestBody = {
      "date": dateString,
      "apps": appsData,
      "userId": childId,
    };

    await _childRepo.postAppUsage(requestBody);
    AppLogger.info('ScreenTimeSyncService: Screentime synced successfully');
  }

  /// Push device info (battery, network, sound profile) to parent
  Future<void> _syncDeviceInfo(String childId) async {
    try {
      final deviceInfo = await _deviceInfoService.getDeviceInfo();
      final data = {
        'child_id': childId,
        'battery_percentage': deviceInfo.batteryPercentage,
        'network_status': deviceInfo.networkStatus,
        'network_type': deviceInfo.networkType,
        'sound_profile': deviceInfo.soundProfile,
        'is_online': deviceInfo.isOnline,
        'last_update': deviceInfo.onlineSince,
      };
      await _childRepo.postChildData(data);
      AppLogger.info('ScreenTimeSyncService: Device info synced successfully');
    } catch (e) {
      AppLogger.error('ScreenTimeSyncService: Device info sync failed: $e');
    }
  }

  /// Check which app icons are missing on backend and upload them
  Future<void> _syncAppIcons(List<AppScreenTimeModel> mergedScreenTime) async {
    try {
      final response = await _childRepo.getAvailableIcons();
      List<String> availableIcons = [];
      if (response.isSuccess && response.data != null) {
        if (response.data is List) {
          availableIcons = (response.data as List)
              .map((e) => e.toString())
              .toList();
        } else if (response.data is Map &&
            (response.data as Map).containsKey('icons')) {
          final iconsData = (response.data as Map)['icons'];
          if (iconsData is List) {
            availableIcons = iconsData.map((e) => e.toString()).toList();
          }
        }
      }

      for (var app in mergedScreenTime) {
        if (!availableIcons.contains(app.package)) {
          final iconBytes = await _deviceInfoService.getAppIcon(app.package);
          if (iconBytes != null && iconBytes.isNotEmpty) {
            await _childRepo.uploadAppIcon(app.package, iconBytes);
          }
        }
      }
    } catch (e) {
      AppLogger.error('ScreenTimeSyncService: Icon sync failed: $e');
    }
  }
}
