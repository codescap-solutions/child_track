import 'dart:convert';
import 'package:child_track/core/constants/app_strings.dart';
import 'package:child_track/core/utils/app_logger.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class GeocodingService {
  static const String _geocodingBaseUrl = 'https://maps.googleapis.com/maps/api/geocode/json';
  static const String _placesBaseUrl = 'https://maps.googleapis.com/maps/api/place';

  // Reverse geocoding: Get address from coordinates
  Future<String?> getAddressFromCoordinates(LatLng location) async {
    try {
      final apiKey = AppStrings.googleMapsApiKey;
      if (apiKey.isEmpty) {
        AppLogger.error('Google Maps API key is not set');
        return null;
      }

      final url = Uri.parse(
        '$_geocodingBaseUrl?latlng=${location.latitude},${location.longitude}&key=$apiKey',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'OK' && data['results'].isNotEmpty) {
          final result = data['results'][0];
          return result['formatted_address'] as String?;
        }
      }
      return null;
    } catch (e) {
      AppLogger.error('Error getting address from coordinates: $e');
      return null;
    }
  }

  // Place search using Text Search API
  Future<List<PlaceSearchResult>> searchPlaces(String query) async {
    try {
      final apiKey = AppStrings.googleMapsApiKey;
      if (apiKey.isEmpty) {
        AppLogger.error('Google Maps API key is not set');
        return [];
      }

      final url = Uri.parse(
        '$_placesBaseUrl/textsearch/json?query=${Uri.encodeComponent(query)}&key=$apiKey',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'OK' && data['results'] != null) {
          final results = data['results'] as List<dynamic>;
          return results.map((result) {
            final geometry = result['geometry'];
            final location = geometry['location'];
            return PlaceSearchResult(
              name: result['name'] ?? '',
              address: result['formatted_address'] ?? '',
              latitude: (location['lat'] ?? 0).toDouble(),
              longitude: (location['lng'] ?? 0).toDouble(),
            );
          }).toList();
        }
      }
      return [];
    } catch (e) {
      AppLogger.error('Error searching places: $e');
      return [];
    }
  }
}

class PlaceSearchResult {
  final String name;
  final String address;
  final double latitude;
  final double longitude;

  PlaceSearchResult({
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
  });

  LatLng get location => LatLng(latitude, longitude);
}

