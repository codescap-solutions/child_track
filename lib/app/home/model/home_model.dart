import 'package:child_track/app/home/model/device_model.dart';
import 'package:child_track/app/home/model/location_info_model.dart';
import 'package:child_track/app/home/model/last_trip_model.dart';
import 'package:child_track/app/home/model/yesterday_trip_summary_model.dart';
import 'package:child_track/app/home/model/cards_model.dart';

class FeatureSummary {
  final int lockedAppsCount;
  final String scrollStatusText;
  final int activeFencesCount;
  final String geoGuardStatusText;

  FeatureSummary({
    required this.lockedAppsCount,
    required this.scrollStatusText,
    required this.activeFencesCount,
    required this.geoGuardStatusText,
  });

  factory FeatureSummary.fromJson(Map<String, dynamic> json) {
    final scrollJson = json['scroll'] ?? {};
    final geoJson = json['geo_guard'] ?? {};
    return FeatureSummary(
      lockedAppsCount: scrollJson['locked_apps_count'] ?? 0,
      scrollStatusText: scrollJson['status_text'] ?? '',
      activeFencesCount: geoJson['active_fences_count'] ?? 0,
      geoGuardStatusText: geoJson['status_text'] ?? '',
    );
  }
}

class TimelineNode {
  final String label;
  final String time;
  final bool isActive;

  TimelineNode({
    required this.label,
    required this.time,
    required this.isActive,
  });

  factory TimelineNode.fromJson(Map<String, dynamic> json) {
    return TimelineNode(
      label: json['label'] ?? '',
      time: json['time'] ?? '',
      isActive: json['is_active'] ?? false,
    );
  }
}

class RouteMapSummary {
  final double totalDistanceKm;
  final int newLocationsCount;
  final List<TimelineNode> timeline;

  RouteMapSummary({
    required this.totalDistanceKm,
    required this.newLocationsCount,
    required this.timeline,
  });

  factory RouteMapSummary.fromJson(Map<String, dynamic> json) {
    double toDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    final list = json['timeline'] as List<dynamic>? ?? [];
    return RouteMapSummary(
      totalDistanceKm: toDouble(json['total_distance_km']),
      newLocationsCount: json['new_locations_count'] ?? 0,
      timeline: list.map((e) => TimelineNode.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}

class AppUsage {
  final String appName;
  final String appIcon;
  final String usageDuration;
  final int usageMinutes;
  final String brandColor;

  AppUsage({
    required this.appName,
    required this.appIcon,
    required this.usageDuration,
    required this.usageMinutes,
    required this.brandColor,
  });

  factory AppUsage.fromJson(Map<String, dynamic> json) {
    return AppUsage(
      appName: json['app_name'] ?? '',
      appIcon: json['appIcon'] ?? '',
      usageDuration: json['usage_duration'] ?? '',
      usageMinutes: json['usage_minutes'] ?? 0,
      brandColor: json['brand_color'] ?? '',
    );
  }
}

class ScreentimeTodaySummary {
  final int totalMinutes;
  final String formattedTotalTime;
  final int dailyLimitMinutes;
  final bool limitExceeded;
  final String limitMessage;
  final List<AppUsage> appUsages;

  ScreentimeTodaySummary({
    required this.totalMinutes,
    required this.formattedTotalTime,
    required this.dailyLimitMinutes,
    required this.limitExceeded,
    required this.limitMessage,
    required this.appUsages,
  });

  factory ScreentimeTodaySummary.fromJson(Map<String, dynamic> json) {
    final list = json['app_usages'] as List<dynamic>? ?? [];
    return ScreentimeTodaySummary(
      totalMinutes: json['total_minutes'] ?? 0,
      formattedTotalTime: json['formatted_total_time'] ?? '',
      dailyLimitMinutes: json['daily_limit_minutes'] ?? 0,
      limitExceeded: json['limit_exceeded'] ?? false,
      limitMessage: json['limit_message'] ?? '',
      appUsages: list.map((e) => AppUsage.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}

class HomeResponse {
  final String? childName;
  final String? childCode;
  final String? childAvatar;
  final bool webFilteringEnabled;
  final DeviceInfo deviceInfo;
  final LocationInfo currentLocation;
  final YesterdayTripSummary? yesterdayTripSummary;
  final Cards? cards;
  final List<TripSegment> yesterdayTrips; // kept for backward compatibility

  // New visual section models
  final FeatureSummary? features;
  final RouteMapSummary? todayRoute;
  final ScreentimeTodaySummary? screentimeToday;
  
  // Shared children tracking list
  final List<SharedChild>? sharedChildren;

  HomeResponse({
    this.childName,
    this.childCode,
    this.childAvatar,
    this.webFilteringEnabled = false,
    required this.deviceInfo,
    required this.currentLocation,
    this.yesterdayTripSummary,
    this.cards,
    this.yesterdayTrips = const [],
    this.features,
    this.todayRoute,
    this.screentimeToday,
    this.sharedChildren,
  });

  factory HomeResponse.fromJson(Map<String, dynamic> json) {
    final sharedList = json['shared_children'] as List<dynamic>? ?? [];
    return HomeResponse(
      childName: json['child_name'] as String?,
      childCode: json['child_code'] as String?,
      childAvatar: (json['child_avatar'] ?? json['avatar']) as String?,
      webFilteringEnabled: json['web_filtering_enabled'] ?? false,
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
      yesterdayTrips:
          json['yesterday_trip_summary'] != null &&
              json['yesterday_trip_summary'] is List
          ? (json['yesterday_trip_summary'] as List<dynamic>)
                .map(
                  (trip) => TripSegment.fromJson(trip as Map<String, dynamic>),
                )
                .toList()
          : [],
      features: json['features'] != null
          ? FeatureSummary.fromJson(json['features'] as Map<String, dynamic>)
          : null,
      todayRoute: json['today_route'] != null
          ? RouteMapSummary.fromJson(json['today_route'] as Map<String, dynamic>)
          : null,
      screentimeToday: json['screentime_today'] != null
          ? ScreentimeTodaySummary.fromJson(json['screentime_today'] as Map<String, dynamic>)
          : null,
      sharedChildren: sharedList
          .map((e) => SharedChild.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class SharedChild {
  final String shareId;
  final String childId;
  final String childName;
  final double latitude;
  final double longitude;
  final int batteryPercentage;
  final DateTime? lastSyncAt;
  final String? avatar;
  final DateTime? expiresAt;

  SharedChild({
    required this.shareId,
    required this.childId,
    required this.childName,
    required this.latitude,
    required this.longitude,
    required this.batteryPercentage,
    this.lastSyncAt,
    this.avatar,
    this.expiresAt,
  });

  factory SharedChild.fromJson(Map<String, dynamic> json) {
    double toDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    return SharedChild(
      shareId: json['share_id']?.toString() ?? json['id']?.toString() ?? '',
      childId: json['child_id']?.toString() ?? '',
      childName: json['child_name']?.toString() ?? '',
      latitude: toDouble(json['latitude'] ?? json['lat']),
      longitude: toDouble(json['longitude'] ?? json['lng']),
      batteryPercentage: json['battery_percentage'] ?? json['battery'] ?? 0,
      lastSyncAt: json['last_sync_at'] != null ? DateTime.tryParse(json['last_sync_at']) : null,
      avatar: (json['avatar'] ?? json['child_avatar'])?.toString(),
      expiresAt: json['expires_at'] != null ? DateTime.tryParse(json['expires_at']) : null,
    );
  }
}
