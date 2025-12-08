import 'package:child_track/core/constants/app_strings.dart';
import 'package:child_track/core/services/location_service.dart';
import 'package:geolocator/geolocator.dart';

class ChildGoogleMapsRepo {
  final String mapKey = AppStrings.googleMapsApiKey;
  final LocationService _locationService = LocationService();

  Future<Position?> getChildLocation() async {
    try {
      Position? position = await _locationService.getCurrentPosition();
      if (position == null) {
        throw Exception(
          'Failed to get current location. Please check location permissions.',
        );
      }
      return position;
    } catch (e) {
      throw Exception('Error getting child location: $e');
    }
  }

  Future<double> getDistanceBetweenTwoPoints(
    Position point1,
    Position point2,
  ) async {
    final distance = await _locationService.getDistanceBetweenTwoPoints(
      point1,
      point2,
    );
    return distance;
  }

  /// Get address and place name from coordinates using LocationService
  Future<Map<String, String>?> getAddressAndPlaceName(
    double latitude,
    double longitude,
  ) async {
    try {
      return await _locationService.getAddressAndPlaceName(latitude, longitude);
    } catch (e) {
      return {'address': 'Unknown', 'place_name': 'Unknown'};
    }
  }
}
