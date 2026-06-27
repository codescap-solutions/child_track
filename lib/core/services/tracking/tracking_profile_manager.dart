import 'package:geolocator/geolocator.dart';

/// Adaptive tracking profiles — interval + distance filter change based on
/// detected activity mode to balance accuracy against battery.
enum TrackingProfile { walking, vehicle, still }

class TrackingProfileConfig {
  final Duration interval;
  final int distanceFilter; // metres
  final String label;

  const TrackingProfileConfig({
    required this.interval,
    required this.distanceFilter,
    required this.label,
  });
}

class TrackingProfileManager {
  static const _profiles = {
    TrackingProfile.walking: TrackingProfileConfig(
      interval: Duration(seconds: 5),
      distanceFilter: 5,
      label: 'Walking',
    ),
    TrackingProfile.vehicle: TrackingProfileConfig(
      interval: Duration(seconds: 3),
      distanceFilter: 5,
      label: 'Vehicle',
    ),
    TrackingProfile.still: TrackingProfileConfig(
      interval: Duration(seconds: 15),
      distanceFilter: 5,
      label: 'Still',
    ),
  };

  TrackingProfile _current = TrackingProfile.still;

  TrackingProfile get currentProfile => _current;
  TrackingProfileConfig get currentConfig => _profiles[_current]!;

  /// Update profile based on detected speed (m/s). Returns true if changed.
  bool updateFromSpeed(double speedMs) {
    final next = _profileFromSpeed(speedMs);
    if (next == _current) return false;
    _current = next;
    return true;
  }

  /// Force a specific profile (e.g. from Activity Recognition).
  bool setProfile(TrackingProfile profile) {
    if (profile == _current) return false;
    _current = profile;
    return true;
  }

  static TrackingProfile _profileFromSpeed(double speedMs) {
    if (speedMs > 5.0) return TrackingProfile.vehicle;
    if (speedMs > 0.6) return TrackingProfile.walking;
    return TrackingProfile.still;
  }

  /// Build [AndroidSettings] for the current profile.
  AndroidSettings buildAndroidSettings() {
    final cfg = currentConfig;
    return AndroidSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: cfg.distanceFilter,
      forceLocationManager: false, // ← Fused Location Provider
      intervalDuration: cfg.interval,
      foregroundNotificationConfig: const ForegroundNotificationConfig(
        notificationTitle: 'NaviQ Active',
        notificationText: 'Tracking location...',
        notificationIcon: AndroidResource(name: 'ic_launcher'),
      ),
    );
  }

  /// Build [AppleSettings] for the current profile.
  AppleSettings buildAppleSettings() {
    final cfg = currentConfig;
    return AppleSettings(
      accuracy: LocationAccuracy.high,
      activityType: _current == TrackingProfile.vehicle
          ? ActivityType.automotiveNavigation
          : ActivityType.fitness,
      distanceFilter: cfg.distanceFilter,
      pauseLocationUpdatesAutomatically: false,
      showBackgroundLocationIndicator: true,
    );
  }

  static TrackingProfileConfig configFor(TrackingProfile p) => _profiles[p]!;
}
