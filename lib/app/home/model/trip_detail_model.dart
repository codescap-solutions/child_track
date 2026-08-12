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

/// A single route point with its timestamp preserved (unlike
/// [PolylineParser.parse]'s plain LatLng output), so route points can be
/// bucketed into [ActivitySegment]s by time range for per-segment polyline
/// coloring.
class RoutePoint {
  final LatLng position;
  final DateTime? timestamp;

  RoutePoint({required this.position, this.timestamp});

  factory RoutePoint.fromJson(Map<String, dynamic> json) {
    final lat = json['lat'] ?? json['latitude'];
    final lng = json['lng'] ?? json['longitude'];
    DateTime? ts;
    if (json['ts'] != null) {
      ts = DateTime.tryParse(json['ts'].toString());
    }
    return RoutePoint(
      position: LatLng(safeToDouble(lat), safeToDouble(lng)),
      timestamp: ts,
    );
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

class DrivingEventInfo {
  final String eventType;
  final double value;
  final String timestamp;
  final double lat;
  final double lng;

  DrivingEventInfo({
    required this.eventType,
    required this.value,
    required this.timestamp,
    required this.lat,
    required this.lng,
  });

  factory DrivingEventInfo.fromJson(Map<String, dynamic> json) {
    return DrivingEventInfo(
      eventType: json['event_type'] ?? '',
      value: safeToDouble(json['value']),
      timestamp: json['timestamp'] ?? '',
      lat: safeToDouble(json['lat']),
      lng: safeToDouble(json['lng']),
    );
  }

  /// Human-readable label for the banner/list (e.g. "Hard braking").
  String get label {
    switch (eventType) {
      case 'hard_braking':
        return 'Hard braking';
      case 'rapid_acceleration':
        return 'Rapid acceleration';
      case 'overspeed':
        return 'Overspeed';
      case 'harsh_turn':
        return 'Harsh turn';
      default:
        return eventType;
    }
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
  final List<RoutePoint> timedRoute;
  final List<TripEvent> events;
  final List<ActivitySegment> segments;
  // Confirmed + Estimated distance split (Part B) — kept as separate labeled
  // figures rather than blended into one number.
  final double distanceConfirmedKm;
  final double distanceEstimatedKm;
  final double distanceTotalKm;
  final List<DrivingEventInfo> drivingEvents;
  final bool hasDangerousDriving;

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
    this.timedRoute = const [],
    required this.events,
    required this.segments,
    this.distanceConfirmedKm = 0,
    this.distanceEstimatedKm = 0,
    this.distanceTotalKm = 0,
    this.drivingEvents = const [],
    this.hasDangerousDriving = false,
  });

  // Helper getters to keep compatibility with existing view properties
  double get totalDistanceKm => distanceMeters / 1000.0;
  double get maxSpeedKmph => maxSpeedMps * 3.6;
  int get steps => 0;
  double get walkingKm => 0.0;

  /// Whether the confirmed/estimated split is meaningful enough to show
  /// (i.e. there's a real gap contributing distance) rather than always
  /// showing a redundant "X confirmed + 0.0 estimated" subtext.
  bool get hasEstimatedDistance => distanceEstimatedKm > 0.05;

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
      rideMode: json['rideMode'] ?? json['ride_mode'] ?? 'unknown',
      polylinePoints: PolylineParser.parse(routeData),
      timedRoute: (routeData is List)
          ? routeData
                .whereType<Map>()
                .map((e) => RoutePoint.fromJson(Map<String, dynamic>.from(e)))
                .toList()
          : const [],
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
      distanceConfirmedKm: safeToDouble(json['distance_confirmed_km']),
      distanceEstimatedKm: safeToDouble(json['distance_estimated_km']),
      distanceTotalKm: json['distance_total_km'] != null
          ? safeToDouble(json['distance_total_km'])
          : dist / 1000.0,
      drivingEvents: (json['driving_events'] as List<dynamic>?)
              ?.map((e) => DrivingEventInfo.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      hasDangerousDriving: json['has_dangerous_driving'] == true,
    );
  }
}
