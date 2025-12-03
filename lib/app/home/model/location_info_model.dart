class LocationInfo {
  final double lat;
  final double lng;
  final String address;
  final String placeName;
  final String since;
  final int durationMinutes;

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
      lat: (json['lat'] ?? 0).toDouble(),
      lng: (json['lng'] ?? 0).toDouble(),
      address: json['address'] ?? '',
      placeName: json['place_name'] ?? '',
      since: json['since'] ?? '',
      durationMinutes: json['duration_minutes'] ?? 0,
    );
  }
}
