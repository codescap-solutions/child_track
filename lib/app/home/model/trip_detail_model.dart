class TripEvent {
  final String eventType;
  final String title;
  final String time;
  final double? distanceKm;
  final int? durationMinutes;
  final double? maxSpeedKmph;

  TripEvent({
    required this.eventType,
    required this.title,
    required this.time,
    this.distanceKm,
    this.durationMinutes,
    this.maxSpeedKmph,
  });

  factory TripEvent.fromJson(Map<String, dynamic> json) {
    return TripEvent(
      eventType: json['event_type'] ?? '',
      title: json['title'] ?? '',
      time: json['time'] ?? '',
      distanceKm: json['distance_km'] != null
          ? (json['distance_km'] as num).toDouble()
          : null,
      durationMinutes: json['duration_minutes'],
      maxSpeedKmph: json['max_speed_kmph'] != null
          ? (json['max_speed_kmph'] as num).toDouble()
          : null,
    );
  }
}

class TripDetailResponse {
  final String tripId;
  final String startTime;
  final String endTime;
  final double totalDistanceKm;
  final int steps;
  final double walkingKm;
  final double maxSpeedKmph;
  final List<String> polylinePoints;
  final List<TripEvent> events;

  TripDetailResponse({
    required this.tripId,
    required this.startTime,
    required this.endTime,
    required this.totalDistanceKm,
    required this.steps,
    required this.walkingKm,
    required this.maxSpeedKmph,
    required this.polylinePoints,
    required this.events,
  });

  factory TripDetailResponse.fromJson(Map<String, dynamic> json) {
    return TripDetailResponse(
      tripId: json['trip_id'] ?? '',
      startTime: json['start_time'] ?? '',
      endTime: json['end_time'] ?? '',
      totalDistanceKm: (json['total_distance_km'] ?? 0).toDouble(),
      steps: json['steps'] ?? 0,
      walkingKm: (json['walking_km'] ?? 0).toDouble(),
      maxSpeedKmph: (json['max_speed_kmph'] ?? 0).toDouble(),
      polylinePoints: (json['polyline_points'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      events: (json['events'] as List<dynamic>?)
              ?.map((event) => TripEvent.fromJson(event as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

