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
  ///
  /// The `still` profile gets a genuinely low-power config — confirmed
  /// (2026-08-16) as the main iOS battery-drain source: with
  /// pauseLocationUpdatesAutomatically:false and LocationAccuracy.high
  /// applied even while stationary, CoreLocation's GPS chip never sleeps —
  /// a child sitting still for hours (asleep, in class) kept it running at
  /// max precision the whole time. `walking`/`vehicle` are untouched (same
  /// high accuracy, no auto-pause) since those only run while the child is
  /// actually moving, where full precision matters and there's nothing to
  /// pause. Safe to relax `still` specifically because:
  ///  - pauseLocationUpdatesAutomatically:true only pauses once iOS's own
  ///    motion coprocessor confirms no movement, and resumes automatically
  ///    (fast, motion-triggered) the moment real movement starts — trip
  ///    start detection isn't meaningfully delayed.
  ///  - Geofence entry/exit uses a separate OS-level region-monitoring API,
  ///    independent of this position stream — unaffected either way.
  AppleSettings buildAppleSettings() {
    final cfg = currentConfig;
    final isStill = _current == TrackingProfile.still;
    return AppleSettings(
      accuracy: isStill ? LocationAccuracy.medium : LocationAccuracy.high,
      activityType: _current == TrackingProfile.vehicle
          ? ActivityType.automotiveNavigation
          : ActivityType.fitness,
      distanceFilter: isStill ? 75 : cfg.distanceFilter,
      pauseLocationUpdatesAutomatically: isStill,
      showBackgroundLocationIndicator: true,
    );
  }

  static TrackingProfileConfig configFor(TrackingProfile p) => _profiles[p]!;
}
