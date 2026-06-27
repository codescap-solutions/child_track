import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';

double safeToDouble(dynamic value, [double defaultValue = 0.0]) {
  if (value == null) return defaultValue;
  if (value is num) return value.toDouble();
  if (value is String) {
    return double.tryParse(value) ?? defaultValue;
  }
  return defaultValue;
}

double? safeToDoubleNullable(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String) {
    return double.tryParse(value);
  }
  return null;
}

int safeToInt(dynamic value, [int defaultValue = 0]) {
  if (value == null) return defaultValue;
  if (value is num) return value.toInt();
  if (value is String) {
    if (value.contains('.')) {
      return double.tryParse(value)?.toInt() ?? defaultValue;
    }
    return int.tryParse(value) ?? defaultValue;
  }
  return defaultValue;
}

int? safeToIntNullable(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toInt();
  if (value is String) {
    if (value.contains('.')) {
      return double.tryParse(value)?.toInt();
    }
    return int.tryParse(value);
  }
  return null;
}

class PolylineParser {
  static List<LatLng> parse(dynamic rawPolyline) {
    if (rawPolyline == null) return [];
    
    // Check if rawPolyline is a list of coordinate maps
    if (rawPolyline is List) {
      final List<LatLng> points = [];
      for (final item in rawPolyline) {
        if (item is Map) {
          final latVal = item['lat'] ?? item['latitude'];
          final lngVal = item['lng'] ?? item['longitude'];
          if (latVal != null && lngVal != null) {
            points.add(LatLng(
              safeToDouble(latVal),
              safeToDouble(lngVal),
            ));
          }
        } else if (item is String) {
          points.addAll(decodePolyline(item));
        }
      }
      if (points.isNotEmpty) return points;
    }
    
    // Check if rawPolyline is a single encoded polyline string
    if (rawPolyline is String) {
      final trimmed = rawPolyline.trim();
      if (trimmed.startsWith('[')) {
        try {
          final parsedJson = json.decode(trimmed);
          return parse(parsedJson);
        } catch (_) {}
      }
      return decodePolyline(trimmed);
    }
    
    return [];
  }

  static List<LatLng> decodePolyline(String encoded) {
    List<LatLng> poly = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        if (index >= len) break;
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        if (index >= len) break;
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      poly.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return poly;
  }
}
