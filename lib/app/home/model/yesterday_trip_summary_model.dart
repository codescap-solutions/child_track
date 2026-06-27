import 'package:child_track/app/home/model/point_model.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:child_track/core/utils/parser_utils.dart';

class YesterdayTripSummary {
  final String tripId;
  final String startTime;
  final String endTime;
  final Point startPoint;
  final Point endPoint;
  final List<LatLng> polylinePoints;
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
      polylinePoints: PolylineParser.parse(json['polyline_points']),
      totalDistanceKm: safeToDouble(json['total_distance_km']),
      totalDurationMinutes: safeToInt(json['total_duration_minutes']),
      maxSpeedKmph: safeToDouble(json['max_speed_kmph']),
      steps: safeToInt(json['steps']),
      walkingKm: safeToDouble(json['walking_km']),
      percentageVsPreviousDay: safeToInt(json['percentage_vs_previous_day']),
      totalScreenTimeSeconds: safeToInt(json['total_screen_time_seconds']),
      eventsCount: safeToInt(json['events_count']),
    );
  }
}
