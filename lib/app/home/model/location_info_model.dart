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
      // The server's actual ISO device_timestamp for this location comes
      // through as last_updated_at — last_update/since_time (checked below
      // as fallbacks) are either not present or, for since_time, a
      // human-display string like "06:11 pm" that DateTime.tryParse can't
      // parse. Confirmed against a real /parent/home response: since_time
      // held "06:11 pm" while last_updated_at held the real ISO timestamp,
      // so this field was silently getting the unparseable display string
      // instead. It happened to fail open safely everywhere it's consumed
      // (HomepageBloc._isNewerLocationUpdate treats unparseable as "newer,
      // apply it"), but the timestamp itself was never the one actually in
      // the response.
      since:
          json['last_updated_at'] ??
          json['last_update'] ??
          json['since_time'] ??
          '',
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
