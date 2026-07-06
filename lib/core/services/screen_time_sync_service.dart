import 'dart:io';
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
  // Short cache on iOS (data changes only at threshold crossings)
  // Longer cache on Android (continuous data available)
  static final Duration _cacheDuration = Platform.isIOS 
      ? const Duration(seconds: 30) 
      : const Duration(minutes: 5);

  ScreenTimeSyncService(this._deviceInfoService, this._childRepo, this._prefs);

  /// Check if cache is still valid
  bool _isCacheValid() {
    if (_screenTimeCache == null || _lastFetchTime == null) return false;
    return DateTime.now().difference(_lastFetchTime!).inMinutes <
        _cacheDuration.inMinutes;
  }

  /// Public entry point: icon sync only.
  /// Call this after a screen-time upload to upload any missing app icons.
  /// Skips the usage-permission check and data-fetching overhead.
  Future<void> syncAppIconsOnly(List<AppScreenTimeModel> mergedScreenTime) async {
    if (!Platform.isAndroid) return;
    final childId = _prefs.getString('child_id');
    if (childId == null || childId.isEmpty) {
      AppLogger.warning('ScreenTimeSyncService [syncAppIconsOnly]: child_id missing, skipping');
      return;
    }
    await _syncAppIcons(mergedScreenTime);
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

    // On iOS: DeviceActivity API returns usage data directly via ScreenTimeManager
    // (App Group shared storage written by DeviceActivityMonitor extension).
    // Skip Android-specific installed app enumeration + allowlist merge.
    if (Platform.isIOS) {
      AppLogger.info('ScreenTimeSyncService: iOS - fetching screen time from native');
      final screenTimeUsage = await _deviceInfoService.getScreenTime();
      final monitoredApps = await _deviceInfoService.getMonitoredApps();

      final usageMap = {for (var app in screenTimeUsage) app.package: app};
      final List<AppScreenTimeModel> mergedList = [];

      for (var monitoredApp in monitoredApps) {
        final id = monitoredApp['id'] as String;
        final displayName = monitoredApp['displayName'] as String? ?? id;

        if (usageMap.containsKey(id)) {
          mergedList.add(usageMap[id]!);
          usageMap.remove(id);
        } else {
          mergedList.add(AppScreenTimeModel(
            package: id,
            appName: displayName,
            seconds: 0,
            isSystemApp: false,
            lastTimeUsed: 0,
          ));
        }
      }

      mergedList.addAll(usageMap.values);
      mergedList.sort((a, b) => b.seconds.compareTo(a.seconds));
      
      _screenTimeCache = mergedList;
      _lastFetchTime = DateTime.now();
      return mergedList;
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
      usageMap.remove(app.packageName);
    }

    // Add remaining apps from usageMap that weren't in installed apps
    usageMap.forEach((package, usageModel) {
      mergedScreenTime.add(
        usageModel.copyWith(
          appName: usageModel.appName.isNotEmpty
              ? usageModel.appName
              : package,
        ),
      );
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
    if (mergedScreenTime.isEmpty) {
      AppLogger.info('ScreenTimeSyncService: No usage data to upload yet.');
      return;
    }

    // On iOS, load the resolved token-to-label map from SharedPrefs
    // This map was saved during FamilyActivityPicker selection
    Map<String, String> tokenLabelMap = {};
    if (Platform.isIOS) {
      final mapStr = _prefs.getString('ios_token_label_map') ?? '';
      if (mapStr.isNotEmpty) {
        for (final entry in mapStr.split('||')) {
          final parts = entry.split('::');
          if (parts.length == 2 && parts[0].isNotEmpty) {
            tokenLabelMap[parts[0]] = parts[1];
          }
        }
      }
    }

    final appsData = mergedScreenTime.map((app) {
      // For iOS: use resolved name from token map if available
      String appName = app.appName;
      if (Platform.isIOS && tokenLabelMap.containsKey(app.package)) {
        appName = tokenLabelMap[app.package]!;
      }
      return {
        "packageName": app.package,
        "usageTime": app.seconds,
        "appName": appName,
        "isSystemApp": false,
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
      "platform": Platform.isIOS ? "ios" : "android",
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

  /// Check which app icons are missing on backend and upload them.
  ///
  /// Fixes applied:
  ///   1. Parses both `"packages"` and `"icons"` response keys (backward compat)
  ///   2. Normalises package names into a `Set<String>` (trim + lowercase)
  ///   3. Uploads only icons that are NOT already on the server
  ///   4. Gracefully skips null / empty icon bytes — never throws
  ///   5. Structured logging: server count, check count, missing count, per-icon result
  ///   6. Uploads up to 5 icons concurrently using Future.wait()
  ///   7. Calls GET /available-icons exactly once per sync cycle (cached in `availableIcons`)
  Future<void> _syncAppIcons(List<AppScreenTimeModel> mergedScreenTime) async {
    // Icon extraction only makes sense on Android — iOS always returns null.
    if (!Platform.isAndroid) return;

    try {
      // ── Step 7: Fetch available icons list — ONE call per sync cycle ──────
      final response = await _childRepo.getAvailableIcons();

      // ── Step 1 + 2: Parse both key formats, normalize, deduplicate ────────
      Set<String> availableIcons = {};
      if (response.isSuccess && response.data != null) {
        final data = response.data;
        List<dynamic> rawList = [];

        if (data is List) {
          // Legacy: bare array at root
          rawList = data;
        } else if (data is Map) {
          // Current backend: { "packages": [...] }
          // Older backend:   { "icons": [...] }
          // Support BOTH for backward compatibility.
          rawList = (data['packages'] as List?)
              ?? (data['icons'] as List?)
              ?? [];
        }

        availableIcons = rawList
            .map((e) => e.toString().trim().toLowerCase())
            .where((e) => e.isNotEmpty)
            .toSet();
      }

      // Filter to apps with a non-empty package name
      final appsToCheck = mergedScreenTime
          .where((app) => app.package.trim().isNotEmpty)
          .toList();

      // ── Step 5: Structured logging ────────────────────────────────────────
      AppLogger.info(
        'ScreenTimeSyncService [IconSync] '
        'Available on server : ${availableIcons.length} | '
        'Installed apps      : ${appsToCheck.length}',
      );

      // ── Step 3: Build list of apps whose icons are missing ────────────────
      final List<AppScreenTimeModel> missingApps = appsToCheck
          .where((app) =>
              !availableIcons.contains(app.package.trim().toLowerCase()))
          .toList();

      AppLogger.info(
        'ScreenTimeSyncService [IconSync] Missing icons : ${missingApps.length}',
      );

      if (missingApps.isEmpty) {
        AppLogger.info(
          'ScreenTimeSyncService [IconSync] All icons already on server — no upload needed.',
        );
        return;
      }

      // ── Step 6: Upload with concurrency limit of 5 ────────────────────────
      const int concurrencyLimit = 5;
      int uploadedCount = 0;
      int skippedCount  = 0;
      int failedCount   = 0;

      for (int i = 0; i < missingApps.length; i += concurrencyLimit) {
        final batch = missingApps.skip(i).take(concurrencyLimit).toList();

        await Future.wait(batch.map((app) async {
          try {
            // ── Step 4: Skip null / empty bytes gracefully ─────────────────
            final iconBytes =
                await _deviceInfoService.getAppIcon(app.package);

            if (iconBytes == null || iconBytes.isEmpty) {
              AppLogger.warning(
                'ScreenTimeSyncService [IconSync] '
                'Skipping ${app.package} — no icon bytes returned.',
              );
              skippedCount++;
              return;
            }

            await _childRepo.uploadAppIcon(app.package, iconBytes);
            AppLogger.info(
              'ScreenTimeSyncService [IconSync] ✓ Uploaded : ${app.package}',
            );
            uploadedCount++;
          } catch (e) {
            // Non-fatal: log and continue with remaining icons
            AppLogger.error(
              'ScreenTimeSyncService [IconSync] ✗ Failed  : ${app.package} — $e',
            );
            failedCount++;
          }
        }));
      }

      AppLogger.info(
        'ScreenTimeSyncService [IconSync] Done — '
        'Uploaded: $uploadedCount | '
        'Skipped: $skippedCount | '
        'Failed: $failedCount',
      );
    } catch (e) {
      AppLogger.error('ScreenTimeSyncService: Icon sync failed: $e');
    }
  }
}
