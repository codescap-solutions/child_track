import 'package:child_track/core/utils/parser_utils.dart';

class TripPoint {
  final double lat;
  final double lng;
  final String ts;
  final double speed; // m/s
  final double accuracy; // meters
  final double bearing; // degrees

  TripPoint({
    required this.lat,
    required this.lng,
    required this.ts,
    this.speed = 0.0,
    this.accuracy = 0.0,
    this.bearing = 0.0,
  });

  double get speedKmh => speed * 3.6;

  factory TripPoint.fromJson(Map<String, dynamic> json) {
    return TripPoint(
      lat: safeToDouble(json['lat']),
      lng: safeToDouble(json['lng']),
      ts: json['ts'] ?? '',
      speed: safeToDouble(json['speed']),
      accuracy: safeToDouble(json['accuracy']),
      bearing: safeToDouble(json['bearing']),
    );
  }
}

class Trip {
  final String tripId;
  final String dayLabel;
  final String startTime;
  final String endTime;
  final String distanceKm;
  final int eventsCount;
  final String fromPlace;
  final String toPlace;
  final List<TripPoint> points;
  final String rideMode;
  // "ongoing" | "ended" | "cancelled" (backend Trip.status, verbatim).
  // Empty string if the backend response predates this field.
  final String status;
  bool get isOngoing => status == 'ongoing';

  Trip({
    required this.tripId,
    required this.dayLabel,
    required this.startTime,
    required this.endTime,
    required this.distanceKm,
    required this.eventsCount,
    required this.fromPlace,
    required this.toPlace,
    required this.points,
    required this.rideMode,
    this.status = '',
  });

  factory Trip.fromJson(Map<String, dynamic> json) {
    final points =
        (json['points'] as List<dynamic>?)
            ?.map((e) => TripPoint.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    final String parsedStartTime = points.isNotEmpty
        ? points.first.ts
        : (json['start_time'] ?? '');
    // For an ONGOING trip, points.last.ts is just whichever point the fetch
    // happened to catch last — NOT a real end time, since the trip keeps
    // growing after this response is rendered. Only trust points.last.ts as
    // an "end time" for a trip that's actually finished; an ongoing trip
    // has no end time at all (see isOngoing / the UI's "LIVE" handling
    // instead of a static range).
    final bool ongoing = (json['status'] ?? '') == 'ongoing';
    final String parsedEndTime = ongoing
        ? ''
        : (points.isNotEmpty ? points.last.ts : (json['end_time'] ?? ''));

    // Defensive parsing for distance_km
    String parsedDistance = '0.0';
    if (json['distance_km'] != null) {
      parsedDistance = safeToDouble(json['distance_km']).toString();
    }

    return Trip(
      tripId: json['trip_id'] ?? '',
      dayLabel: json['day_label'] ?? '',
      startTime: _getData(parsedStartTime),
      endTime: _getData(parsedEndTime),
      distanceKm: parsedDistance,
      eventsCount: safeToInt(json['events_count']),
      fromPlace: json['from_place'] ?? '',
      toPlace: json['to_place'] ?? '',
      points: points,
      rideMode: json['ride_mode'] ?? json['rideMode'] ?? 'unknown',
      status: json['status'] ?? '',
    );
  }
}

String _getData(String? time) {
  if (time == null || time.isEmpty) return '';
  return time;
}

class TripListResponse {
  final List<Trip> trips;
  final int page;
  final int pageSize;
  final int totalItems;

  TripListResponse({
    required this.trips,
    required this.page,
    required this.pageSize,
    required this.totalItems,
  });

  factory TripListResponse.fromJson(Map<String, dynamic> json) {
    return TripListResponse(
      trips:
          (json['trips'] as List<dynamic>?)
              ?.map((trip) => Trip.fromJson(trip as Map<String, dynamic>))
              .toList() ??
          [],
      page: safeToInt(json['page'], 1),
      pageSize: safeToInt(json['page_size'], 10),
      totalItems: safeToInt(json['total_items']),
    );
  }
}
