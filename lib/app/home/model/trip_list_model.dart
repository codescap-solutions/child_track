import 'package:intl/intl.dart';

class TripPoint {
  final double lat;
  final double lng;
  final String ts;

  TripPoint({required this.lat, required this.lng, required this.ts});

  factory TripPoint.fromJson(Map<String, dynamic> json) {
    return TripPoint(
      lat: (json['lat'] ?? 0).toDouble(),
      lng: (json['lng'] ?? 0).toDouble(),
      ts: json['ts'] ?? '',
    );
  }
}

class Trip {
  final String tripId;
  final String dayLabel;

  /// Raw UTC ISO string from the backend (e.g. "2026-02-22T07:45:41.000Z").
  /// NEVER format/mangle this at the model layer — the view converts to local.
  final String startTime;

  /// Raw UTC ISO string. May be empty if the trip is still active.
  final String endTime;

  final String distanceKm;
  final int eventsCount;
  final String fromPlace;
  final String toPlace;
  final List<TripPoint> points;
  final String rideMode;

  /// Backend trip status: "active", "end_candidate", "ended"
  final String status;

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
    this.status = 'ended',
  });

  /// Parse the start time into a local DateTime.
  DateTime? get startTimeLocal {
    if (startTime.isEmpty) return null;
    try {
      return DateTime.parse(startTime).toLocal();
    } catch (_) {
      return null;
    }
  }

  /// Parse the end time into a local DateTime.
  DateTime? get endTimeLocal {
    if (endTime.isEmpty) return null;
    try {
      return DateTime.parse(endTime).toLocal();
    } catch (_) {
      return null;
    }
  }

  /// Human-readable local start time (e.g. "2:15 pm").
  String get startTimeFormatted {
    final dt = startTimeLocal;
    if (dt == null) return '';
    return DateFormat('h:mm a').format(dt).toLowerCase();
  }

  /// Human-readable local end time (e.g. "3:30 pm").
  String get endTimeFormatted {
    final dt = endTimeLocal;
    if (dt == null) return 'Ongoing';
    return DateFormat('h:mm a').format(dt).toLowerCase();
  }

  /// Duration string (e.g. "1hr 15 min" or "45 min").
  String get durationFormatted {
    final start = startTimeLocal;
    final end = endTimeLocal;
    if (start == null || end == null) return '';
    final duration = end.difference(start);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours > 0) {
      return '(${hours}hr${hours > 1 ? 's' : ''} ${minutes > 0 ? '$minutes min' : ''})'
          .trim();
    }
    return '($minutes min)';
  }

  /// Day group label for UI headers (e.g. "Today", "Yesterday", "Feb 20").
  String get dayGroupLabel {
    final dt = startTimeLocal;
    if (dt == null) return dayLabel;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tripDay = DateTime(dt.year, dt.month, dt.day);

    if (tripDay == today) return 'Today';
    if (tripDay == today.subtract(const Duration(days: 1))) return 'Yesterday';
    return DateFormat('MMM d').format(dt);
  }

  bool get isActive => status.toLowerCase() == 'active';

  factory Trip.fromJson(Map<String, dynamic> json) {
    final points =
        (json['points'] as List<dynamic>?)
            ?.map((e) => TripPoint.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    // Keep raw ISO strings — do NOT mangle to a custom format
    String startTimeRaw = json['start_time']?.toString() ?? '';
    String endTimeRaw = json['end_time']?.toString() ?? '';

    // If end_time is missing but we have points, use the last point's timestamp
    if (endTimeRaw.isEmpty && points.isNotEmpty) {
      endTimeRaw = points.last.ts;
    }

    return Trip(
      tripId: json['trip_id'] ?? '',
      dayLabel: json['day_label'] ?? '',
      startTime: startTimeRaw,
      endTime: endTimeRaw,
      distanceKm: (json['distance_km'] ?? 0).toString(),
      eventsCount: json['events_count'] ?? 0,
      fromPlace: json['from_place'] ?? '',
      toPlace: json['to_place'] ?? '',
      points: points,
      rideMode: json['ride_mode'] ?? 'vehicle',
      status: json['status'] ?? 'ended',
    );
  }
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
      page: json['page'] ?? 1,
      pageSize: json['page_size'] ?? 10,
      totalItems: json['total_items'] ?? 0,
    );
  }
}
