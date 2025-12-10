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

    return Point(
      name: json['name'] ?? '',
      lat: _toDouble(json['lat']),
      lng: _toDouble(json['lng']),
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

