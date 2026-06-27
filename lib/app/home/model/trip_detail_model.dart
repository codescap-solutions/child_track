import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:child_track/core/utils/parser_utils.dart';

class TripEvent {
  final String eventType;
  final String description;
  final String timestamp;
  final double lat;
  final double lng;
  final Map<String, dynamic>? metadata;

  TripEvent({
    required this.eventType,
    required this.description,
    required this.timestamp,
    required this.lat,
    required this.lng,
    this.metadata,
  });

  factory TripEvent.fromJson(Map<String, dynamic> json) {
    return TripEvent(
      eventType: json['event_type'] ?? '',
      description: json['description'] ?? json['title'] ?? '',
      timestamp: json['timestamp'] ?? json['time'] ?? '',
      lat: safeToDouble(json['lat']),
      lng: safeToDouble(json['lng']),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  // Backward compatibility getters
  String get title => description;
  String get time => timestamp;

  double? get distanceKm {
    if (metadata != null && metadata!['distanceMeters'] != null) {
      return safeToDouble(metadata!['distanceMeters']) / 1000.0;
    }
    if (metadata != null && metadata!['distance_km'] != null) {
      return safeToDouble(metadata!['distance_km']);
    }
    return null;
  }

  int? get durationMinutes {
    if (metadata != null && metadata!['durationSeconds'] != null) {
      return (safeToInt(metadata!['durationSeconds']) / 60.0).round();
    }
    if (metadata != null && metadata!['duration_minutes'] != null) {
      return safeToInt(metadata!['duration_minutes']);
    }
    return null;
  }

  double? get maxSpeedKmph {
    if (metadata != null && metadata!['maxSpeedMps'] != null) {
      return safeToDouble(metadata!['maxSpeedMps']) * 3.6;
    }
    if (metadata != null && metadata!['max_speed_kmph'] != null) {
      return safeToDouble(metadata!['max_speed_kmph']);
    }
    return null;
  }
}

class ActivitySegment {
  final String segmentId;
  final String type;
  final String startTime;
  final String endTime;
  final int durationSeconds;
  final double distanceMeters;
  final double averageSpeedMps;
  final double maxSpeedMps;

  ActivitySegment({
    required this.segmentId,
    required this.type,
    required this.startTime,
    required this.endTime,
    required this.durationSeconds,
    required this.distanceMeters,
    required this.averageSpeedMps,
    required this.maxSpeedMps,
  });

  factory ActivitySegment.fromJson(Map<String, dynamic> json) {
    return ActivitySegment(
      segmentId: json['segment_id'] ?? json['segmentId'] ?? '',
      type: json['type'] ?? 'unknown',
      startTime: json['start_time'] ?? json['startTime'] ?? '',
      endTime: json['end_time'] ?? json['endTime'] ?? '',
      durationSeconds: safeToInt(json['duration'] ?? json['durationSeconds']),
      distanceMeters: safeToDouble(json['distance'] ?? json['distanceMeters']),
      averageSpeedMps: safeToDouble(json['average_speed'] ?? json['averageSpeed']),
      maxSpeedMps: safeToDouble(json['max_speed'] ?? json['maxSpeed']),
    );
  }
}

class TripDetailResponse {
  final String tripId;
  final String startTime;
  final String endTime;
  final double distanceMeters;
  final int durationSeconds;
  final double averageSpeedMps;
  final double maxSpeedMps;
  final String rideMode;
  final List<LatLng> polylinePoints;
  final List<TripEvent> events;
  final List<ActivitySegment> segments;

  TripDetailResponse({
    required this.tripId,
    required this.startTime,
    required this.endTime,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.averageSpeedMps,
    required this.maxSpeedMps,
    required this.rideMode,
    required this.polylinePoints,
    required this.events,
    required this.segments,
  });

  // Helper getters to keep compatibility with existing view properties
  double get totalDistanceKm => distanceMeters / 1000.0;
  double get maxSpeedKmph => maxSpeedMps * 3.6;
  int get steps => 0;
  double get walkingKm => 0.0;

  factory TripDetailResponse.fromJson(Map<String, dynamic> json) {
    // Determine route field (new format uses 'route', fallback to 'polyline_points')
    final routeData = json['route'] ?? json['polyline_points'];
    
    // Determine events field (new format uses 'timeline', fallback to 'events')
    final eventsData = json['timeline'] ?? json['events'];

    // Safely parse speed and distance fields
    final dist = safeToDouble(json['distance'] ?? (safeToDouble(json['total_distance_km']) * 1000.0));
    final dur = safeToInt(json['duration'] ?? (safeToInt(json['total_duration_minutes']) * 60));
    final avgSpeed = safeToDouble(json['average_speed'] ?? (safeToDouble(json['average_speed_kmph']) / 3.6));
    final maxSpeed = safeToDouble(json['max_speed'] ?? (safeToDouble(json['max_speed_kmph']) / 3.6));

    return TripDetailResponse(
      tripId: json['trip_id'] ?? '',
      startTime: json['start_time'] ?? '',
      endTime: json['end_time'] ?? '',
      distanceMeters: dist,
      durationSeconds: dur,
      averageSpeedMps: avgSpeed,
      maxSpeedMps: maxSpeed,
      rideMode: json['rideMode'] ?? json['ride_mode'] ?? 'vehicle',
      polylinePoints: PolylineParser.parse(routeData),
      events: (eventsData as List<dynamic>?)
              ?.map(
                (event) => TripEvent.fromJson(event as Map<String, dynamic>),
              )
              .toList() ??
          [],
      segments: (json['segments'] as List<dynamic>?)
              ?.map(
                (segment) => ActivitySegment.fromJson(segment as Map<String, dynamic>),
              )
              .toList() ??
          [],
    );
  }
}
