class Trip {
  final String tripId;
  final String dayLabel;
  final String startTime;
  final String endTime;
  final double distanceKm;
  final int eventsCount;
  final String fromPlace;
  final String toPlace;

  Trip({
    required this.tripId,
    required this.dayLabel,
    required this.startTime,
    required this.endTime,
    required this.distanceKm,
    required this.eventsCount,
    required this.fromPlace,
    required this.toPlace,
  });

  factory Trip.fromJson(Map<String, dynamic> json) {
    return Trip(
      tripId: json['trip_id'] ?? '',
      dayLabel: json['day_label'] ?? '',
      startTime: json['start_time'] ?? '',
      endTime: json['end_time'] ?? '',
      distanceKm: (json['distance_km'] ?? 0).toDouble(),
      eventsCount: json['events_count'] ?? 0,
      fromPlace: json['from_place'] ?? '',
      toPlace: json['to_place'] ?? '',
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
      trips: (json['trips'] as List<dynamic>?)
              ?.map((trip) => Trip.fromJson(trip as Map<String, dynamic>))
              .toList() ??
          [],
      page: json['page'] ?? 1,
      pageSize: json['page_size'] ?? 10,
      totalItems: json['total_items'] ?? 0,
    );
  }
}

