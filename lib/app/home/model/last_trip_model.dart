import 'package:child_track/app/home/model/trip_list_model.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:child_track/core/utils/parser_utils.dart';

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
  final String rideMode;
  final int eventsCount;

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
    required this.rideMode,
    required this.eventsCount,
  });

  factory TripSegment.fromJson(Map<String, dynamic> json) {
    return TripSegment(
      segmentId: json['segment_id'] ?? '',
      type: json['type'] ?? '',
      startTime: json['start_time'] ?? '',
      endTime: json['end_time'] ?? '',
      startPlace: json['start_point']?['name'] ?? '',
      endPlace: json['end_point']?['name'] ?? '',
      distanceKm: safeToDouble(json['distance_km']),
      durationMinutes: safeToInt(json['duration_minutes']),
      maxSpeedKmph: safeToDouble(json['max_speed_kmph']),
      polylinePoints: PolylineParser.parse(json['polyline_points']),
      startLocation: LatLng(
        safeToDouble(json['start_latitude'] ?? json['start_point']?['lat']),
        safeToDouble(json['start_longitude'] ?? json['start_point']?['lng']),
      ),
      endLocation: LatLng(
        safeToDouble(json['end_latitude'] ?? json['end_point']?['lat']),
        safeToDouble(json['end_longitude'] ?? json['end_point']?['lng']),
      ),
      progress: safeToDouble(json['progress']),
      rideMode: json['rideMode'] ?? json['ride_mode'] ?? 'vehicle',
      eventsCount: safeToInt(json['events_count']),
    );
  }

  factory TripSegment.fromTrip(Trip trip) {
    return TripSegment(
      segmentId: trip.tripId,
      type: 'ride',
      startTime: trip.startTime,
      endTime: trip.endTime,
      startPlace: trip.fromPlace.isNotEmpty ? trip.fromPlace : 'Unknown Location',
      endPlace: trip.toPlace.isNotEmpty ? trip.toPlace : 'Unknown Location',
      distanceKm: double.tryParse(trip.distanceKm) ?? 0.0,
      durationMinutes: _calculateDurationMinutes(trip.startTime, trip.endTime),
      maxSpeedKmph: _calculateMaxSpeedKmph(trip.points),
      polylinePoints: trip.points.map((p) => LatLng(p.lat, p.lng)).toList(),
      startLocation: trip.points.isNotEmpty
          ? LatLng(trip.points.first.lat, trip.points.first.lng)
          : const LatLng(0, 0),
      endLocation: trip.points.isNotEmpty
          ? LatLng(trip.points.last.lat, trip.points.last.lng)
          : const LatLng(0, 0),
      progress: 100.0,
      rideMode: trip.rideMode,
      eventsCount: trip.eventsCount,
    );
  }

  static double _calculateMaxSpeedKmph(List<TripPoint> points) {
    if (points.length < 2) return 0.0;
    double maxKmh = 0.0;
    for (int i = 1; i < points.length; i++) {
      final prev = points[i - 1];
      final curr = points[i];
      final pointSpeedKmh = curr.speedKmh;
      if (pointSpeedKmh > 0 && pointSpeedKmh < 250) {
        if (pointSpeedKmh > maxKmh) maxKmh = pointSpeedKmh;
        continue;
      }
      try {
        final distM = Geolocator.distanceBetween(
          prev.lat, prev.lng, curr.lat, curr.lng,
        );
        final prevTs = DateTime.parse(prev.ts);
        final currTs = DateTime.parse(curr.ts);
        final deltaS = currTs.difference(prevTs).inSeconds.abs();
        if (deltaS > 0 && deltaS < 120) {
          final speedKmh = (distM / deltaS) * 3.6;
          if (speedKmh > maxKmh && speedKmh < 250) maxKmh = speedKmh;
        }
      } catch (_) {}
    }
    return double.parse(maxKmh.toStringAsFixed(1));
  }

  static int _calculateDurationMinutes(String startStr, String endStr) {
    try {
      final start = DateTime.parse(startStr);
      final end = DateTime.parse(endStr);
      return end.difference(start).inMinutes;
    } catch (_) {
      return 0;
    }
  }
}
