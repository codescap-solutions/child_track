import 'package:child_track/app/home/model/trip_list_model.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

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
  final List<LatLng> polylinePoints;
  final LatLng startLocation;
  final LatLng endLocation;
  final double progress;

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
    required this.startLocation,
    required this.endLocation,
    required this.progress,
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
      polylinePoints: (json['polyline_points'] as List<dynamic>)
          .map(
            (point) => LatLng(point['latitude'] ?? 0, point['longitude'] ?? 0),
          )
          .toList(),
      startLocation: LatLng(
        json['start_latitude'] ?? 0,
        json['start_longitude'] ?? 0,
      ),
      endLocation: LatLng(
        json['end_latitude'] ?? 0,
        json['end_longitude'] ?? 0,
      ),
      progress: (json['progress'] ?? 0).toDouble(),
    );
  }

  factory TripSegment.fromTrip(Trip trip) {
    return TripSegment(
      segmentId: trip.tripId,
      type: 'ride',
      startTime: trip.startTime,
      endTime: trip.endTime,
      startPlace: trip.fromPlace.isNotEmpty
          ? trip.fromPlace
          : 'Unknown Location',
      endPlace: trip.toPlace.isNotEmpty ? trip.toPlace : 'Unknown Location',
      distanceKm: double.tryParse(trip.distanceKm) ?? 0.0,
      durationMinutes: _calculateDurationMinutes(trip.startTime, trip.endTime),
      maxSpeedKmph: 0.0,
      polylinePoints: trip.points.map((p) => LatLng(p.lat, p.lng)).toList(),
      startLocation: trip.points.isNotEmpty
          ? LatLng(trip.points.first.lat, trip.points.first.lng)
          : const LatLng(0, 0),
      endLocation: trip.points.isNotEmpty
          ? LatLng(trip.points.last.lat, trip.points.last.lng)
          : const LatLng(0, 0),
      progress: 100.0,
    );
  }

  static int _calculateDurationMinutes(String start, String end) {
    try {
      String toIso(String s) {
        final parts = s.split(' ');
        if (parts.length != 2) return s;
        final dateParts = parts[0].split('-');
        if (dateParts.length != 3) return s;
        return "${dateParts[2]}-${dateParts[1]}-${dateParts[0]} ${parts[1]}";
      }

      final s = DateTime.parse(toIso(start));
      final e = DateTime.parse(toIso(end));
      return e.difference(s).inMinutes;
    } catch (_) {
      return 0;
    }
  }
}
