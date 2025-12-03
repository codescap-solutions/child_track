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
    // Helper function to safely convert to double (handles both string and number)
    double _toDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) {
        return double.tryParse(value) ?? 0.0;
      }
      return 0.0;
    }

    return ActivityCard(
      steps: json['steps'] ?? 0,
      walkingKm: _toDouble(json['walking_km']),
      routeKm: _toDouble(json['route_km']),
      maxSpeedKmph: _toDouble(json['max_speed_kmph']),
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

