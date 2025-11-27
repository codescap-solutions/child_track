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
}
