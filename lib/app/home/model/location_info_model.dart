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
    // Helper function to safely convert to double (handles both string and number)
    double _toDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) {
        return double.tryParse(value) ?? 0.0;
      }
      return 0.0;
    }

    return LocationInfo(
      lat: _toDouble(json['lat']),
      lng: _toDouble(json['lng']),
      address: json['address'] ?? '',
      placeName: json['place_name'] ?? '',
      since: json['since'] ?? '',
      durationMinutes: json['duration_minutes'] ?? 0,
    );
  }
}
