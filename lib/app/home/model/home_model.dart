import 'package:child_track/app/home/model/device_model.dart';
import 'package:child_track/app/home/model/location_info_model.dart';
import 'package:child_track/app/home/model/last_trip_model.dart';

class HomeResponse {
  final DeviceInfo deviceInfo;
  final LocationInfo currentLocation;
  final List<TripSegment> yesterdayTrips; // list of last 3 trips

  HomeResponse({
    required this.deviceInfo,
    required this.currentLocation,
    required this.yesterdayTrips,
  });

  factory HomeResponse.fromJson(Map<String, dynamic> json) {
    return HomeResponse(
      deviceInfo: DeviceInfo.fromJson(json['device_info']),
      currentLocation: LocationInfo.fromJson(json['current_location']),
      yesterdayTrips: json['yesterday_trips']
          .map((trip) => TripSegment.fromJson(trip))
          .toList(),
    );
  }
}
