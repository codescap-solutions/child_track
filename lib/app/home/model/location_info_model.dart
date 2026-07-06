import 'package:child_track/core/utils/parser_utils.dart';

class LocationInfo {
  final double lat;
  final double lng;
  final String address;
  final String placeName;
  final String since;
  final num durationMinutes;

  LocationInfo({
    required this.lat,
    required this.lng,
    required this.address,
    required this.placeName,
    required this.since,
    required this.durationMinutes,
  });

  factory LocationInfo.fromJson(Map<String, dynamic> json) {
    return LocationInfo(
      lat: safeToDouble(json['lat'] ?? json['latitude']),
      lng: safeToDouble(json['lng'] ?? json['longitude']),
      address: json['address'] ?? '',
      placeName: json['place_name'] ?? '',
      since: json['last_update'] ?? json['since_time'] ?? '',
      durationMinutes: safeToInt(json['duration_minutes']),
    );
  }

  LocationInfo copyWith({
    double? lat,
    double? lng,
    String? address,
    String? placeName,
    String? since,
    num? durationMinutes,
  }) {
    return LocationInfo(
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      address: address ?? this.address,
      placeName: placeName ?? this.placeName,
      since: since ?? this.since,
      durationMinutes: durationMinutes ?? this.durationMinutes,
    );
  }
}
