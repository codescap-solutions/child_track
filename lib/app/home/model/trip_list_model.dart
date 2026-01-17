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
  final String startTime;
  final String endTime;
  final String distanceKm;
  final int eventsCount;
  final String fromPlace;
  final String toPlace;
  final List<TripPoint> points;

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
  });

  factory Trip.fromJson(Map<String, dynamic> json) {
    final points =
        (json['points'] as List<dynamic>?)
            ?.map((e) => TripPoint.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    String? endTimeRaw = json['end_time'];
    if ((endTimeRaw == null || endTimeRaw.isEmpty) && points.isNotEmpty) {
      endTimeRaw = points.last.ts;
    }

    return Trip(
      tripId: json['trip_id'] ?? '',
      dayLabel: json['day_label'] ?? '',
      startTime: _getData(json['start_time']),
      endTime: _getData(endTimeRaw),
      distanceKm: (json['distance_km'] ?? 0).toString(),
      eventsCount: json['events_count'] ?? 0,
      fromPlace: json['from_place'] ?? '',
      toPlace: json['to_place'] ?? '',
      points: points,
    );
  }
}

String _getData(String? time) {
  if (time == null) return '';
  String date = time.split('T').first.split('-').reversed.join('-');
  String times = time.split('T').last.split('.').first;
  return "$date $times";
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
