class TripSegment {
  final String segmentId;
  final String type; // ride, walk, stop
  final String startTime;
  final String endTime;
  final String startPlace;
  final String endPlace;
  final double distanceKm;
  final int durationMinutes;
  final double maxSpeedKmph;
  final List<dynamic> polylinePoints;

  TripSegment({
    required this.segmentId,
    required this.type,
    required this.startTime,
    required this.endTime,
    required this.startPlace,
    required this.endPlace,
    required this.distanceKm,
    required this.durationMinutes,
    required this.maxSpeedKmph,
    required this.polylinePoints,
  });

  factory TripSegment.fromJson(Map<String, dynamic> json) {
    return TripSegment(
      segmentId: json['segment_id'] ?? '',
      type: json['type'] ?? '',
      startTime: json['start_time'] ?? '',
      endTime: json['end_time'] ?? '',
      startPlace: json['start_point']?['name'] ?? '',
      endPlace: json['end_point']?['name'] ?? '',
      distanceKm: (json['distance_km'] ?? 0).toDouble(),
      durationMinutes: json['duration_minutes'] ?? 0,
      maxSpeedKmph: (json['max_speed_kmph'] ?? 0).toDouble(),
      polylinePoints: json['polyline_points'] ?? [],
    );
  }
}
