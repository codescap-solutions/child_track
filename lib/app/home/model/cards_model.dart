import 'package:child_track/core/utils/parser_utils.dart';

class ActivityCard {
  final int steps;
  final double walkingKm;
  final double routeKm;
  final double maxSpeedKmph;
  final int improvementPercentage;

  ActivityCard({
    required this.steps,
    required this.walkingKm,
    required this.routeKm,
    required this.maxSpeedKmph,
    required this.improvementPercentage,
  });

  factory ActivityCard.fromJson(Map<String, dynamic> json) {
    return ActivityCard(
      steps: safeToInt(json['steps']),
      walkingKm: safeToDouble(json['walking_km']),
      routeKm: safeToDouble(json['route_km']),
      maxSpeedKmph: safeToDouble(json['max_speed_kmph']),
      improvementPercentage: safeToInt(json['improvement_percentage']),
    );
  }
}

class ScreenTimeCard {
  final int totalSeconds;

  ScreenTimeCard({
    required this.totalSeconds,
  });

  factory ScreenTimeCard.fromJson(Map<String, dynamic> json) {
    return ScreenTimeCard(
      totalSeconds: safeToInt(json['total_seconds']),
    );
  }
}

class Cards {
  final ActivityCard activityYesterday;
  final ScreenTimeCard screentimeYesterday;

  Cards({
    required this.activityYesterday,
    required this.screentimeYesterday,
  });

  factory Cards.fromJson(Map<String, dynamic> json) {
    return Cards(
      activityYesterday: ActivityCard.fromJson(
        json['activity_yesterday'] ?? {},
      ),
      screentimeYesterday: ScreenTimeCard.fromJson(
        json['screentime_yesterday'] ?? {},
      ),
    );
  }
}
