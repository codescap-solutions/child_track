import 'dart:io';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart'
    as permission_handler;
import '../utils/app_logger.dart';
import '../utils/structured_logger.dart';
import '../../app/addplace/service/geocoding_service.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  /// Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    try {
      return await Geolocator.isLocationServiceEnabled();
    } catch (e) {
      AppLogger.error('Error checking location service: $e');
      return false;
    }
  }

  /// Check location permission status
  Future<LocationPermission> checkPermission() async {
    try {
      final status = await Geolocator.checkPermission();
      StructuredLogger.log(LogTag.PERM, 'Permission check → $status');
      return status;
    } catch (e) {
      AppLogger.error('Error checking permission: $e');
      StructuredLogger.log(LogTag.PERM, 'Permission check failed', error: e);
      return LocationPermission.denied;
    }
  }

  /// Request location permission (foreground and background)
  Future<LocationPermission> requestPermission() async {
    try {
      // First check if location services are enabled
      bool serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        AppLogger.warning('Location services are disabled');
        StructuredLogger.log(
          LogTag.GPS,
          'Permission request aborted — location services disabled',
        );
        return LocationPermission.denied;
      }

      // Step 1: Request foreground location permission first
      LocationPermission permission = await checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        StructuredLogger.log(
          LogTag.PERM,
          'Foreground permission request result → $permission',
        );
        if (permission == LocationPermission.denied) {
          return LocationPermission.denied;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return LocationPermission.deniedForever;
      }

      // Step 2: For Android 10+ (API 29+), request background location permission separately
      if (Platform.isAndroid) {
        try {
          // Check if we have "always" permission, if not, request background permission
          if (permission == LocationPermission.whileInUse) {
            final backgroundStatus =
                await permission_handler.Permission.locationAlways.status;

            if (!backgroundStatus.isGranted) {
              final backgroundPermission = await permission_handler
                  .Permission
                  .locationAlways
                  .request();

              if (backgroundPermission.isGranted) {
                permission = LocationPermission.always;
              } else if (backgroundPermission.isPermanentlyDenied) {
                permission = LocationPermission.deniedForever;
              } else {
                permission = LocationPermission.denied;
              }
              StructuredLogger.log(
                LogTag.PERM,
                'Background permission request result → $backgroundPermission',
              );
            } else {
              permission = LocationPermission.always;
            }
          }
        } catch (e) {
          AppLogger.error(
            'Error requesting background location permission: $e',
          );
          StructuredLogger.log(
            LogTag.PERM,
            'Background permission request failed',
            error: e,
          );
          // Continue with foreground permission if background request fails
        }
      }

      StructuredLogger.log(LogTag.PERM, 'requestPermission() final → $permission');
      return permission;
    } catch (e) {
      AppLogger.error('Error requesting permission: $e');
      StructuredLogger.log(LogTag.PERM, 'requestPermission() failed', error: e);
      return LocationPermission.denied;
    }
  }

  /// Snapshot of the "Allow all the time" background location permission —
  /// distinct from the plain foreground "granted" status (Permission.location
  /// / LocationPermission.whileInUse is also reported as "granted" for that).
  /// Native OS-level geofencing (Android GeofencingClient, iOS
  /// CLCircularRegion background monitoring) specifically needs the
  /// "always" grant to survive the app being backgrounded/killed. Confirmed
  /// as the likely root cause of a real incident: two Android devices
  /// (Oppo/OnePlus), both with foreground location "granted" and OEM
  /// battery whitelisting already acknowledged, where every geofence
  /// notification for months came from the slow location-point fallback
  /// and never once from the fast native path — nothing in the app
  /// actually checked or surfaced this specific gap before now.
  /// Returns "granted", "denied", "not_applicable" (unsupported platform),
  /// or "unknown" (check itself failed).
  Future<String> getBackgroundLocationStatus() async {
    try {
      if (Platform.isIOS) {
        final permission = await Geolocator.checkPermission();
        return permission == LocationPermission.always ? 'granted' : 'denied';
      }
      if (Platform.isAndroid) {
        final status = await permission_handler.Permission.locationAlways.status;
        return status.isGranted ? 'granted' : 'denied';
      }
      return 'not_applicable';
    } catch (e) {
      AppLogger.error('Error checking background location status: $e');
      return 'unknown';
    }
  }

  /// Request location permission and ensure it's set to "always allow"
  /// Returns true if "always allow" permission is granted, false otherwise
  /// Returns a map with 'granted' (bool) and 'needsSettings' (bool) to indicate if user needs to go to settings
  Future<Map<String, dynamic>> requestAlwaysAllowPermission() async {
    try {
      // First check if location services are enabled
      bool serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        StructuredLogger.log(
          LogTag.GPS,
          'Always-allow permission request aborted — location services disabled',
        );
        return {'granted': false, 'needsSettings': false};
      }

      // Step 1: Request foreground location permission first
      LocationPermission permission = await checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return {'granted': false, 'needsSettings': false};
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return {'granted': false, 'needsSettings': true};
      }

      // Step 2: Ensure we have "always allow" permission
      // For iOS, check if we need to request "always" permission
      if (Platform.isIOS) {
        if (permission == LocationPermission.whileInUse) {
          // On iOS, we need to request "always" permission explicitly
          permission = await Geolocator.requestPermission();
          // Note: iOS may show a system dialog asking to change to "always"
          // The user needs to manually change it in settings if denied
        }
      }

      // Step 3: For Android 10+ (API 29+), request background location permission separately
      if (Platform.isAndroid) {
        if (permission == LocationPermission.whileInUse) {
          final backgroundStatus =
              await permission_handler.Permission.locationAlways.status;

          if (!backgroundStatus.isGranted) {
            // Request background permission - this will show system dialog
            // On Android 10+, this may show a dialog that guides user to Settings
            final backgroundPermission = await permission_handler
                .Permission
                .locationAlways
                .request();

            if (backgroundPermission.isGranted) {
              permission = LocationPermission.always;
            } else if (backgroundPermission.isPermanentlyDenied) {
              return {'granted': false, 'needsSettings': true};
            } else {
              // On Android 10+, if not granted, user typically needs to go to Settings
              // The system dialog usually guides them there

              return {'granted': false, 'needsSettings': true};
            }
          } else {
            permission = LocationPermission.always;
          }
        }
      }

      // Final check: ensure we have "always" permission
      final finalPermission = await checkPermission();
      final hasAlwaysPermission = finalPermission == LocationPermission.always;

      final result = {
        'granted': hasAlwaysPermission,
        'needsSettings':
            !hasAlwaysPermission && permission == LocationPermission.whileInUse,
      };
      StructuredLogger.log(
        LogTag.PERM,
        'requestAlwaysAllowPermission() final → $finalPermission '
        '(granted=${result['granted']}, needsSettings=${result['needsSettings']})',
      );
      return result;
    } catch (e) {
      AppLogger.error('Error requesting always allow permission: $e');
      StructuredLogger.log(
        LogTag.PERM,
        'requestAlwaysAllowPermission() failed',
        error: e,
      );
      return {'granted': false, 'needsSettings': false};
    }
  }

  /// Open app settings so user can manually enable "always allow" permission
  Future<bool> openLocationSettings() async {
    try {
      // On Android 10+, users need to go to Settings to enable "Always allow"
      // even if they've granted "While using the app" permission
      // Open app settings to allow user to change permission
      return await permission_handler.openAppSettings();
    } catch (e) {
      AppLogger.error('Error opening location settings: $e');
      return false;
    }
  }

  /// Open system location settings (GPS toggle)
  Future<bool> openSystemLocationSettings() async {
    try {
      return await Geolocator.openLocationSettings();
    } catch (e) {
      AppLogger.error('Error opening system location settings: $e');
      return false;
    }
  }

  /// Get current position
  Future<Position?> getCurrentPosition() async {
    try {
      // Request permission first
      LocationPermission permission = await requestPermission();
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        return null;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      return position;
    } catch (e) {
      AppLogger.error('Error getting current position: $e');
      return null;
    }
  }

  /// Get last known position
  Future<Position?> getLastKnownPosition() async {
    try {
      Position? position = await Geolocator.getLastKnownPosition();
      return position;
    } catch (e) {
      AppLogger.error('Error getting last known position: $e');
      return null;
    }
  }

  /// Stream of position updates (works in foreground and background)
  /// Note: For reliable background tracking when app is killed, consider using
  /// a foreground service or WorkManager package
  Stream<Position>? getPositionStream(int distanceFilter) {
    try {
      return Geolocator.getPositionStream(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: distanceFilter,
        ),
      );
    } catch (e) {
      AppLogger.error('Error getting position stream: $e');
      return null;
    }
  }

  Future<double> getDistanceBetweenTwoPoints(
    Position point1,
    Position point2,
  ) async {
    try {
      return Geolocator.distanceBetween(
        point1.latitude,
        point1.longitude,
        point2.latitude,
        point2.longitude,
      );
    } catch (e) {
      AppLogger.error('Error getting distance between two points: $e');
      return 0;
    }
  }

  /// Get address and place name from coordinates using reverse geocoding
  Future<Map<String, String>?> getAddressAndPlaceName(
    double latitude,
    double longitude,
  ) async {
    try {
      final geocodingService = GeocodingService();
      final location = LatLng(latitude, longitude);

      // Get address from coordinates
      final address = await geocodingService.getAddressFromCoordinates(
        location,
      );

      if (address == null) {
        return {'address': 'Unknown', 'place_name': 'Unknown'};
      }

      // Extract place name from address (first part before comma, or use a shorter version)
      // You can also use Places API for more accurate place names, but for now we'll parse the address
      final placeName = _extractPlaceNameFromAddress(address);

      return {'address': address, 'place_name': placeName};
    } catch (e) {
      AppLogger.error('Error getting address and place name: $e');
      return {'address': 'Unknown', 'place_name': 'Unknown'};
    }
  }

  /// Extract place name from formatted address
  /// Takes the first meaningful part of the address (usually the street or locality)
  String _extractPlaceNameFromAddress(String address) {
    try {
      // Split by comma and get the first part (usually the most specific location)
      final parts = address.split(',');
      if (parts.isNotEmpty) {
        // Return the first part, trimmed
        return parts[0].trim();
      }
      return address;
    } catch (e) {
      AppLogger.error('Error extracting place name: $e');
      return address;
    }
  }
}
