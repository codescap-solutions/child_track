import 'dart:convert';

import 'package:child_track/core/services/base_service.dart';
import 'package:child_track/core/services/dio_client.dart';
import 'package:child_track/app/home/model/home_model.dart';

class HomeRepository extends BaseService {
  HomeRepository({required DioClient dioClient}) : super(dioClient);

  Future<BaseResponse<HomeResponse>> getHomeData() async {
    await Future.delayed(const Duration(seconds: 1));

    final staticJson = {
      "device_info": {
        "battery_percentage": 85,
        "network_status": "connected",
        "network_type": "wifi",
        "sound_profile": "sound",
        "is_online": true,
        "online_since": "9:30am",
      },
      "current_location": {
        "lat": 11.2488,
        "lng": 75.7839,
        "address": "Cubbon Road, Bengaluru",
        "place_name": "School",
        "since": "9:30am",
        "duration_minutes": 2,
      },
      "yesterday_trip_summary": [
        {
          "segment_id": "S1",
          "type": "ride",
          "start_latitude": 11.2488,
          "start_longitude": 75.7839,
          "end_latitude": 11.2488,
          "end_longitude": 75.7839,
          "start_time": "10:00am",
          "end_time": "12:00pm",
          "start_point": {"name": "Home"},
          "end_point": {"name": "Mall"},
          "distance_km": 6.0,
          "duration_minutes": 120,
          "max_speed_kmph": 40,
          "polyline_points": [
            {"latitude": 11.2488, "longitude": 75.7839},
            {"latitude": 11.2488, "longitude": 75.7839},
          ],
          "progress": 30,
        },
        {
          "segment_id": "S2",
          "type": "ride",
          "start_time": "11:00pm",
          "end_time": "11:30pm",
          "start_point": {"name": "Mall"},
          "end_point": {"name": "Park"},
          "distance_km": 10.5,
          "duration_minutes": 180,
          "max_speed_kmph": 55,
          "start_latitude": 11.2488,
          "start_longitude": 75.7839,
          "end_latitude": 11.2488,
          "end_longitude": 75.7839,
          "polyline_points": [
            {"latitude": 11.2488, "longitude": 75.7839},
            {"latitude": 11.2488, "longitude": 75.7839},
          ],
          "progress": 60,
        },
        {
          "segment_id": "S3",
          "type": "walk",
          "start_time": "10:30pm",
          "end_time": "12:00am",
          "start_latitude": 11.2488,
          "start_longitude": 75.7839,
          "end_latitude": 11.2488,
          "end_longitude": 75.7839,
          "start_point": {"name": "Park"},
          "end_point": {"name": "Ice Cream Shop"},
          "distance_km": 1.2,
          "duration_minutes": 30,
          "max_speed_kmph": 6,
          "polyline_points": [
            {"latitude": 11.2488, "longitude": 75.7839},
            {"latitude": 11.2488, "longitude": 75.7839},
          ],
          "progress": 100,
        },
      ],
    };

    return BaseResponse(
      isSuccess: true,
      message: "Static home data ",
      data: jsonEncode(staticJson),
    );
  }

  Future<BaseResponse> getCurrentLocationDetails() async {
    await Future.delayed(const Duration(seconds: 1));
    return BaseResponse(
      isSuccess: true,
      message: "Static current location details",
      data: jsonEncode({
        "lat": 11.2488,
        "lng": 75.7839,
        "address": "Cubbon Road, Bengaluru",
        "place_name": "School",
        "since": "9:30am",
        "duration_minutes": 120,
      }),
    );
  }
}
