import 'package:child_track/app/home/model/device_model.dart';
import 'package:child_track/app/home/model/location_info_model.dart';
import 'package:child_track/app/home/model/last_trip_model.dart';
import 'package:child_track/app/home/model/yesterday_trip_summary_model.dart';
import 'package:child_track/app/home/model/cards_model.dart';

class HomeResponse {
  final DeviceInfo deviceInfo;
  final LocationInfo currentLocation;
  final YesterdayTripSummary? yesterdayTripSummary;
  final Cards? cards;
  final List<TripSegment> yesterdayTrips; // kept for backward compatibility

  HomeResponse({
    required this.deviceInfo,
    required this.currentLocation,
    this.yesterdayTripSummary,
    this.cards,
    this.yesterdayTrips = const [],
  });

  factory HomeResponse.fromJson(Map<String, dynamic> json) {
    return HomeResponse(
      deviceInfo: DeviceInfo.fromJson(json['device_info'] ?? {}),
      currentLocation: LocationInfo.fromJson(json['current_location'] ?? {}),
      yesterdayTripSummary: json['yesterday_trip_summary'] != null
          ? YesterdayTripSummary.fromJson(
              json['yesterday_trip_summary'] as Map<String, dynamic>,
            )
          : null,
      cards: json['cards'] != null
          ? Cards.fromJson(json['cards'] as Map<String, dynamic>)
          : null,
      yesterdayTrips: json['yesterday_trip_summary'] != null &&
              json['yesterday_trip_summary'] is List
          ? (json['yesterday_trip_summary'] as List<dynamic>)
              .map((trip) => TripSegment.fromJson(trip as Map<String, dynamic>))
              .toList()
          : [],
    );
  }
}
