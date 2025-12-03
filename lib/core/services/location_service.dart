import 'package:geolocator/geolocator.dart';
import '../utils/app_logger.dart';

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

  /// Request location permission
  Future<LocationPermission> requestPermission() async {
    try {
      // First check if location services are enabled
      bool serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        AppLogger.warning('Location services are disabled');
        return LocationPermission.denied;
      }

      // Check current permission status
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

      AppLogger.info('Location permission granted');
      return permission;
    } catch (e) {
      AppLogger.error('Error requesting permission: $e');
      return LocationPermission.denied;
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

  /// Stream of position updates
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
}
