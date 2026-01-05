import 'dart:io';
import 'package:battery_plus/battery_plus.dart';
import 'package:child_track/app/childapp/model/scree_time_model.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/services.dart';
import 'package:child_track/app/home/model/device_model.dart';
import 'package:child_track/app/social_apps/model/installed_app_model.dart';
import 'package:child_track/core/utils/app_logger.dart';

class ChildInfoService {
  final Battery _battery = Battery();
  final Connectivity _connectivity = Connectivity();
  static const MethodChannel _channel = MethodChannel(
    'com.example.child_track/device_info',
  );

  /// Get current device information
  Future<DeviceInfo> getDeviceInfo() async {
    try {
      // Get battery percentage
      final batteryPercentage = await _getBatteryPercentage();

      // Get network information
      final networkInfo = await _getNetworkInfo();

      // Get sound profile
      final soundProfile = await _getSoundProfile();

      return DeviceInfo(
        batteryPercentage: batteryPercentage,
        networkStatus: networkInfo['status'] ?? 'unknown',
        networkType: networkInfo['type'] ?? 'unknown',
        soundProfile: soundProfile,
        isOnline: networkInfo['isOnline'] ?? false,
        onlineSince: _getCurrentTime(),
      );
    } catch (e) {
      AppLogger.error('Error getting device info: $e');
      // Return default values on error
      return DeviceInfo(
        batteryPercentage: 0,
        networkStatus: 'unknown',
        networkType: 'unknown',
        soundProfile: 'unknown',
        isOnline: false,
        onlineSince: _getCurrentTime(),
      );
    }
  }

  /// Get battery percentage
  Future<int> _getBatteryPercentage() async {
    try {
      final batteryLevel = await _battery.batteryLevel;
      return batteryLevel;
    } catch (e) {
      AppLogger.error('Error getting battery percentage: $e');
      return 0;
    }
  }

  /// Get network status and type
  Future<Map<String, dynamic>> _getNetworkInfo() async {
    try {
      final connectivityResults = await _connectivity.checkConnectivity();

      String status = 'disconnected';
      String type = 'none';
      bool isOnline = false;

      // Prioritize connection types: wifi > mobile > ethernet > others
      if (connectivityResults.contains(ConnectivityResult.wifi)) {
        status = 'connected';
        type = 'wifi';
        isOnline = true;
      } else if (connectivityResults.contains(ConnectivityResult.mobile)) {
        status = 'connected';
        type = 'mobile';
        isOnline = true;
      } else if (connectivityResults.contains(ConnectivityResult.ethernet)) {
        status = 'connected';
        type = 'ethernet';
        isOnline = true;
      } else if (connectivityResults.contains(ConnectivityResult.vpn)) {
        status = 'connected';
        type = 'vpn';
        isOnline = true;
      } else if (connectivityResults.contains(ConnectivityResult.bluetooth)) {
        status = 'connected';
        type = 'bluetooth';
        isOnline = true;
      } else if (connectivityResults.contains(ConnectivityResult.other)) {
        status = 'connected';
        type = 'other';
        isOnline = true;
      } else if (connectivityResults.contains(ConnectivityResult.none)) {
        status = 'disconnected';
        type = 'none';
        isOnline = false;
      }

      return {'status': status, 'type': type, 'isOnline': isOnline};
    } catch (e) {
      AppLogger.error('Error getting network info: $e');
      return {'status': 'unknown', 'type': 'unknown', 'isOnline': false};
    }
  }

  /// Get sound profile (ringer mode)
  Future<String> _getSoundProfile() async {
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        final result = await _channel.invokeMethod<String>('getSoundProfile');
        return result ?? 'unknown';
      }
      return 'unknown';
    } catch (e) {
      AppLogger.error('Error getting sound profile: $e');
      return 'unknown';
    }
  }

  /// Get current time in 12-hour format
  String _getCurrentTime() {
    final now = DateTime.now();
    final hour = now.hour > 12
        ? now.hour - 12
        : (now.hour == 0 ? 12 : now.hour);
    final minute = now.minute.toString().padLeft(2, '0');
    final period = now.hour >= 12 ? 'pm' : 'am';
    return '$hour:$minute$period';
  }

  /// Get all installed apps (system and user apps)
  Future<List<InstalledApp>> getInstalledApps() async {
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        final result = await _channel.invokeMethod<List<dynamic>>(
          'getInstalledApps',
        );
        if (result != null) {
          final apps = <InstalledApp>[];
          for (final item in result) {
            try {
              // Convert Map<Object?, Object?> to Map<String, dynamic>
              final map = item as Map;
              final convertedMap = <String, dynamic>{};
              map.forEach((key, value) {
                final stringKey = key.toString();
                // Handle type conversions properly
                if (value == null) {
                  convertedMap[stringKey] = null;
                } else if (value is int || value is String || value is bool) {
                  convertedMap[stringKey] = value;
                } else {
                  convertedMap[stringKey] = value.toString();
                }
              });
              apps.add(InstalledApp.fromJson(convertedMap));
            } catch (e) {
              AppLogger.error('Error parsing app item: $e');
              // Skip this app and continue with the next one
              continue;
            }
          }
          return apps;
        }
      }
      return [];
    } catch (e) {
      AppLogger.error('Error getting installed apps: $e');
      return [];
    }
  }

  //todo: aneesh get screen time and convert to list of AppScreenTimeModel
  Future<List<AppScreenTimeModel>> getScreenTime() async {
    try {
      final result = await _channel.invokeMethod<List<dynamic>>(
        'getScreenTime',
      );
      if (result != null) {
        return result.map((e) {
          final map = Map<String, dynamic>.from(e as Map);
          return AppScreenTimeModel.fromJson(map);
        }).toList();
      }
      return [];
    } catch (e) {
      AppLogger.error('Error getting screen time: $e');
      return [];
    }
  }

  /// Check if usage stats permission is granted
  Future<bool> checkUsagePermission() async {
    try {
      if (Platform.isAndroid) {
        final result = await _channel.invokeMethod<bool>(
          'checkUsagePermission',
        );
        return result ?? false;
      }
      return true; // iOS handles this differently or assumed true for Logic flow until implemented
    } catch (e) {
      AppLogger.error('Error checking usage permission: $e');
      return false;
    }
  }

  /// Open usage settings
  Future<bool> openUsageSettings() async {
    try {
      if (Platform.isAndroid) {
        await _channel.invokeMethod<bool>('openUsageSettings');
        return true;
      }
      return false;
    } catch (e) {
      AppLogger.error('Error opening usage settings: $e');
      return false;
    }
  }
}
