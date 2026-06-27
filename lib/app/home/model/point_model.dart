import 'package:child_track/core/utils/parser_utils.dart';

class Point {
  final String name;
  final double lat;
  final double lng;

  Point({
    required this.name,
    required this.lat,
    required this.lng,
  });

  factory Point.fromJson(Map<String, dynamic> json) {
    return Point(
      name: json['name'] ?? '',
      lat: safeToDouble(json['lat']),
      lng: safeToDouble(json['lng']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'lat': lat,
      'lng': lng,
    };
  }
}
