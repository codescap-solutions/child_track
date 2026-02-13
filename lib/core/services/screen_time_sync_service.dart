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
    return DateTime.now().difference(_lastFetchTime!).inMinutes < _cacheDuration.inMinutes;
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
        hasPermission = _prefs.getBool(hasPermissionKey) ?? false;
        if (!hasPermission) {
          AppLogger.warning('ScreenTimeSyncService: Usage permission not granted (cached)');
          return;
        } else {
          // Cache is valid and permission is granted, proceed with sync
          try {
            final mergedScreenTime = await fetchScreenTimeData();
            if (mergedScreenTime.isEmpty) {
              AppLogger.info('ScreenTimeSyncService: No apps with usage > 0 found.');
              return;
            }

            await uploadScreenTimeData(mergedScreenTime, childId);

            // Save sync time
            _prefs.setString(
              'last_screen_time_sync',
              DateTime.now().toIso8601String(),
            );
            return;
          } catch (e) {
            AppLogger.error('ScreenTimeSyncService: Failed to sync screen time: $e');
            return;
          }
        }
      }
    }

    // Fresh permission check if cache expired or not set
    hasPermission = await _deviceInfoService.checkUsagePermission();
    _prefs.setBool(hasPermissionKey, hasPermission);
    _prefs.setString('${hasPermissionKey}_time', DateTime.now().toIso8601String());
    
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
      AppLogger.info('ScreenTimeSyncService: Returning cached screen time data');
      return _screenTimeCache ?? [];
    }

    final installedApps = await _deviceInfoService.getInstalledApps();
    final screenTimeUsage = await _deviceInfoService.getScreenTime();

    // Popular apps allowlist (package names)
    final allowList = {
      'com.google.android.youtube', // YouTube
      'com.facebook.katana', // Facebook
      'com.instagram.android', // Instagram
      'com.whatsapp', // WhatsApp
      'com.snapchat.android', // Snapchat
      'com.zhiliaoapp.musically', // TikTok
      'org.telegram.messenger', // Telegram
      'com.twitter.android', // Twitter/X
      'com.google.android.apps.maps', // Maps
      'com.spotify.music', // Spotify
      'com.netflix.mediaclient', // Netflix
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
    // 1. Sync Screentime Data
    final appsData = mergedScreenTime.map((app) {
      final json = app.toJson();
      json.remove('icon'); // Remove icon from sync payload
      return json;
    }).toList();

    final requestBody = {
      "child_id": childId,
      "date": DateTime.now().toIso8601String().split('T')[0],
      "total_seconds": mergedScreenTime.fold(
        0,
        (sum, app) => sum + app.seconds,
      ),
      "apps": appsData,
    };

    await _childRepo.postScreenTime(requestBody);
    AppLogger.info('ScreenTimeSyncService: Screentime synced successfully');

    // 2. Check Available Icons & Upload Missing
    await _syncIcons(mergedScreenTime);
  }

  Future<void> _syncIcons(List<AppScreenTimeModel> apps) async {
    try {
      final iconsResponse = await _childRepo.getAvailableIcons();
      Set<String> availableIcons = {};

      if (iconsResponse.isSuccess && iconsResponse.data != null) {
        final data = iconsResponse.data!;
        if (data['data'] != null && data['data']['packages'] != null) {
          final packages = List<String>.from(data['data']['packages']);
          availableIcons = packages.toSet();
        }
      }

      final Map<String, String> iconsToUpload = {};

      for (var app in apps) {
        if (!availableIcons.contains(app.package) &&
            app.iconBase64 != null &&
            app.iconBase64!.isNotEmpty) {
          iconsToUpload[app.package] = app.iconBase64!;
        }
      }

      if (iconsToUpload.isNotEmpty) {
        AppLogger.info(
          'ScreenTimeSyncService: Uploading ${iconsToUpload.length} missing icons',
        );
        await _childRepo.uploadIcons(iconsToUpload);
      }
    } catch (e) {
      AppLogger.error('ScreenTimeSyncService: Failed to sync icons: $e');
    }
  }
}
