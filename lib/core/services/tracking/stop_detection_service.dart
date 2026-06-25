import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:child_track/core/services/tracking/activity_recognition_service.dart';
import 'package:child_track/core/utils/structured_logger.dart';

/// Triggered when a stop has been confidently detected.
class StopEvent {
  final DateTime startedAt;
  final DateTime detectedAt;
  final double centerLat;
  final double centerLng;
  final double radiusMeters;

  const StopEvent({
    required this.startedAt,
    required this.detectedAt,
    required this.centerLat,
    required this.centerLng,
    required this.radiusMeters,
  });

  Duration get duration => detectedAt.difference(startedAt);
}

/// Detects when the device becomes stationary for long enough to end a trip.
///
/// Rules (matching Find My Kids behaviour):
///   • radius ≤ 30 m for all recent points
///   • duration ≥ 120 seconds
///   • activity == STILL  (when AR available)
///   • average speed < 1 km/h (0.28 m/s)
class StopDetectionService {
  static const double _stopRadiusMeters = 30.0;
  static const int _stopDurationSeconds = 120;
  static const double _stopSpeedThresholdMs = 0.28; // 1 km/h

  final _stopController = StreamController<StopEvent>.broadcast();
  Stream<StopEvent> get onStop => _stopController.stream;

  // Rolling window of recent positions
  final List<Position> _window = [];
  DateTime? _windowStart;
  bool _stopped = false;

  void reset() {
    _window.clear();
    _windowStart = null;
    _stopped = false;
  }

  void dispose() {
    _stopController.close();
  }

  /// Call on every new GPS position. Returns true if a stop was just detected.
  bool processPosition(Position pos, ActivityState arState) {
    // If already stopped, keep resetting on movement
    if (pos.speed > _stopSpeedThresholdMs ||
        arState.type == NaviQActivityType.walking ||
        arState.type == NaviQActivityType.running ||
        arState.type == NaviQActivityType.cycling ||
        arState.type == NaviQActivityType.vehicle) {
      reset();
      return false;
    }

    // Add to window
    _window.add(pos);
    if (_window.length > 30) _window.removeAt(0);
    _windowStart ??= pos.timestamp;

    // Need at least 3 points
    if (_window.length < 3) return false;

    // Check radius of all points from centroid
    final centroid = _centroid(_window);
    final maxRadius = _window
        .map(
          (p) => Geolocator.distanceBetween(
            centroid.$1,
            centroid.$2,
            p.latitude,
            p.longitude,
          ),
        )
        .reduce((a, b) => a > b ? a : b);

    if (maxRadius > _stopRadiusMeters) {
      // Points scattered too far — not a clean stop
      reset();
      return false;
    }

    // Duration check
    final duration =
        pos.timestamp.difference(_windowStart!).inSeconds;

    if (duration >= _stopDurationSeconds && !_stopped) {
      _stopped = true;
      final event = StopEvent(
        startedAt: _windowStart!,
        detectedAt: pos.timestamp,
        centerLat: centroid.$1,
        centerLng: centroid.$2,
        radiusMeters: maxRadius,
      );
      _stopController.add(event);
      StructuredLogger.log(
        LogTag.TRIP,
        '[Stop] Detected after ${duration}s within ${maxRadius.toStringAsFixed(1)}m radius',
      );
      return true;
    }

    return false;
  }

  static (double, double) _centroid(List<Position> pts) {
    final lat = pts.map((p) => p.latitude).reduce((a, b) => a + b) / pts.length;
    final lng =
        pts.map((p) => p.longitude).reduce((a, b) => a + b) / pts.length;
    return (lat, lng);
  }
}
