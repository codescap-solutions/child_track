import 'package:child_track/app/home/model/point_model.dart';

class YesterdayTripSummary {
  final String tripId;
  final String startTime;
  final String endTime;
  final Point startPoint;
  final Point endPoint;
  final List<String> polylinePoints;
  final double totalDistanceKm;
  final int totalDurationMinutes;
  final double maxSpeedKmph;
  final int steps;
  final double walkingKm;
  final int percentageVsPreviousDay;
  final int totalScreenTimeSeconds;
  final int eventsCount;

  YesterdayTripSummary({
    required this.tripId,
    required this.startTime,
    required this.endTime,
    required this.startPoint,
    required this.endPoint,
    required this.polylinePoints,
    required this.totalDistanceKm,
    required this.totalDurationMinutes,
    required this.maxSpeedKmph,
    required this.steps,
    required this.walkingKm,
    required this.percentageVsPreviousDay,
    required this.totalScreenTimeSeconds,
    required this.eventsCount,
  });

  factory YesterdayTripSummary.fromJson(Map<String, dynamic> json) {
    return YesterdayTripSummary(
      tripId: json['trip_id'] ?? '',
      startTime: json['start_time'] ?? '',
      endTime: json['end_time'] ?? '',
      startPoint: Point.fromJson(json['start_point'] ?? {}),
      endPoint: Point.fromJson(json['end_point'] ?? {}),
      polylinePoints: (json['polyline_points'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      totalDistanceKm: (json['total_distance_km'] ?? 0).toDouble(),
      totalDurationMinutes: json['total_duration_minutes'] ?? 0,
      maxSpeedKmph: (json['max_speed_kmph'] ?? 0).toDouble(),
      steps: json['steps'] ?? 0,
      walkingKm: (json['walking_km'] ?? 0).toDouble(),
      percentageVsPreviousDay: json['percentage_vs_previous_day'] ?? 0,
      totalScreenTimeSeconds: json['total_screen_time_seconds'] ?? 0,
      eventsCount: json['events_count'] ?? 0,
    );
  }
}

