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
      steps: json['steps'] ?? 0,
      walkingKm: (json['walking_km'] ?? 0).toDouble(),
      routeKm: (json['route_km'] ?? 0).toDouble(),
      maxSpeedKmph: (json['max_speed_kmph'] ?? 0).toDouble(),
      improvementPercentage: json['improvement_percentage'] ?? 0,
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
      totalSeconds: json['total_seconds'] ?? 0,
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

