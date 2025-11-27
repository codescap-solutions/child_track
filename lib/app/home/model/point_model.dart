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
      lat: (json['lat'] ?? 0).toDouble(),
      lng: (json['lng'] ?? 0).toDouble(),
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

