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
        "online_since": "2025-02-10T09:30:00Z",
      },
      "current_location": {
        "lat": 11.2488,
        "lng": 75.7839,
        "address": "Cubbon Road, Bengaluru",
        "place_name": "School",
        "since": "2025-02-10T09:30:00Z",
        "duration_minutes": 120,
      },
      "yesterday_trip_summary": [
        {
          "segment_id": "S1",
          "type": "ride",
          "start_time": "2025-02-09T10:00:00Z",
          "end_time": "2025-02-09T12:00:00Z",
          "start_point": {"name": "Home"},
          "end_point": {"name": "Mall"},
          "distance_km": 6.0,
          "duration_minutes": 120,
          "max_speed_kmph": 40,
          "polyline_points": [],
        },
        {
          "segment_id": "S2",
          "type": "ride",
          "start_time": "2025-02-09T13:00:00Z",
          "end_time": "2025-02-09T16:00:00Z",
          "start_point": {"name": "Mall"},
          "end_point": {"name": "Park"},
          "distance_km": 10.5,
          "duration_minutes": 180,
          "max_speed_kmph": 55,
          "polyline_points": [],
        },
        {
          "segment_id": "S3",
          "type": "walk",
          "start_time": "2025-02-09T16:30:00Z",
          "end_time": "2025-02-09T17:00:00Z",
          "start_point": {"name": "Park"},
          "end_point": {"name": "Ice Cream Shop"},
          "distance_km": 1.2,
          "duration_minutes": 30,
          "max_speed_kmph": 6,
          "polyline_points": [],
        },
      ],
    };

    return BaseResponse(
      isSuccess: true,
      message: "Static home data",
      data: jsonEncode(staticJson),
    );
  }
}
