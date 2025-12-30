import 'dart:io';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart' as permission_handler;
import '../utils/app_logger.dart';
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
      return await Geolocator.checkPermission();
    } catch (e) {
      AppLogger.error('Error checking permission: $e');
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
        return LocationPermission.denied;
      }

      // Step 1: Request foreground location permission first
      LocationPermission permission = await checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          AppLogger.warning('Location permissions are denied');
          return LocationPermission.denied;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        AppLogger.warning('Location permissions are permanently denied');
        return LocationPermission.deniedForever;
      }

      // Step 2: For Android 10+ (API 29+), request background location permission separately
      if (Platform.isAndroid) {
        try {
          // Check if we have "always" permission, if not, request background permission
          if (permission == LocationPermission.whileInUse) {
            AppLogger.info('Requesting background location permission for Android 10+');
            final backgroundStatus = await permission_handler.Permission.locationAlways.status;
            
            if (!backgroundStatus.isGranted) {
              final backgroundPermission = await permission_handler.Permission.locationAlways.request();
              
              if (backgroundPermission.isGranted) {
                AppLogger.info('Background location permission granted');
                permission = LocationPermission.always;
              } else if (backgroundPermission.isPermanentlyDenied) {
                AppLogger.warning('Background location permission permanently denied');
                // User needs to enable it manually in settings
              } else {
                AppLogger.warning('Background location permission denied, but foreground permission granted');
              }
            } else {
              AppLogger.info('Background location permission already granted');
              permission = LocationPermission.always;
            }
          }
        } catch (e) {
          AppLogger.error('Error requesting background location permission: $e');
          // Continue with foreground permission if background request fails
        }
      }

      AppLogger.info('Location permission granted: $permission');
      return permission;
    } catch (e) {
      AppLogger.error('Error requesting permission: $e');
      return LocationPermission.denied;
    }
  }

  /// Request location permission and ensure it's set to "always allow"
  /// Returns true if "always allow" permission is granted, false otherwise
  Future<bool> requestAlwaysAllowPermission() async {
    try {
      // First check if location services are enabled
      bool serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        AppLogger.warning('Location services are disabled');
        return false;
      }

      // Step 1: Request foreground location permission first
      LocationPermission permission = await checkPermission();
      
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          AppLogger.warning('Location permissions are denied');
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        AppLogger.warning('Location permissions are permanently denied');
        return false;
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
          AppLogger.info('Requesting background location permission for Android 10+');
          final backgroundStatus = await permission_handler.Permission.locationAlways.status;
          
          if (!backgroundStatus.isGranted) {
            // Request background permission - this will show system dialog
            final backgroundPermission = await permission_handler.Permission.locationAlways.request();
            
            if (backgroundPermission.isGranted) {
              AppLogger.info('Background location permission granted');
              permission = LocationPermission.always;
            } else if (backgroundPermission.isPermanentlyDenied) {
              AppLogger.warning('Background location permission permanently denied');
              return false; // User needs to enable it manually in settings
            } else {
              AppLogger.warning('Background location permission denied');
              return false; // Not granted, need to request again
            }
          } else {
            AppLogger.info('Background location permission already granted');
            permission = LocationPermission.always;
          }
        }
      }

      // Final check: ensure we have "always" permission
      final finalPermission = await checkPermission();
      final hasAlwaysPermission = finalPermission == LocationPermission.always;
      
      AppLogger.info('Final location permission: $finalPermission, hasAlwaysPermission: $hasAlwaysPermission');
      return hasAlwaysPermission;
    } catch (e) {
      AppLogger.error('Error requesting always allow permission: $e');
      return false;
    }
  }

  /// Open app settings so user can manually enable "always allow" permission
  Future<bool> openLocationSettings() async {
    try {
      // Check if permission is permanently denied
      final backgroundStatus = await permission_handler.Permission.locationAlways.status;
      if (backgroundStatus.isPermanentlyDenied) {
        // Open app settings
        return await permission_handler.openAppSettings();
      }
      return false;
    } catch (e) {
      AppLogger.error('Error opening location settings: $e');
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
        AppLogger.warning('Location permission not granted');
        return null;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      AppLogger.info(
        'Current position: ${position.latitude}, ${position.longitude}',
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
      if (position != null) {
        AppLogger.info(
          'Last known position: ${position.latitude}, ${position.longitude}',
        );
      }
      return position;
    } catch (e) {
      AppLogger.error('Error getting last known position: $e');
      return null;
    }
  }

  /// Stream of position updates (works in foreground and background)
  /// Note: For reliable background tracking when app is killed, consider using
  /// a foreground service or WorkManager package
  Stream<Position>? getPositionStream() {
    try {
      return Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10, // Update every 10 meters
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
        AppLogger.warning('Could not get address from coordinates');
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
