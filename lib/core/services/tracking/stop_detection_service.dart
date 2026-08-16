import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:child_track/core/services/tracking/activity_recognition_service.dart';
import 'package:child_track/core/utils/structured_logger.dart';
import 'package:child_track/core/services/tracking/tracking_config_service.dart';

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

class StopDetectionService {
  final TrackingConfigService _config;

  StopDetectionService({required TrackingConfigService config}) : _config = config;

  final _stopController = StreamController<StopEvent>.broadcast();
  Stream<StopEvent> get onStop => _stopController.stream;

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

  bool processPosition(Position pos, ActivityState arState) {
    final stopRadius = _config.stopRadius;
    final stopDuration = _config.stopDuration;

    // Used to hard-reset the whole window on a single point whose
    // instantaneous GPS speed exceeded speedThreshold, OR whenever
    // activity-recognition reported walking/running/cycling/vehicle for
    // that point. Both are noisy single-sample signals — GPS speed jitters
    // near zero even while genuinely stationary (worse indoors/multipath,
    // e.g. right at home), and Android's ActivityRecognition API is
    // documented to take minutes to settle back to STILL after any motion,
    // so one stale/lagged "walking" event could wipe out several minutes
    // of already-accumulated stillness evidence and restart the whole
    // stopDuration countdown. Confirmed as the cause of a real 14-minute
    // trip-end delay (child actually stopped at 8 min, per a competitor
    // app's report, but this service didn't confirm the stop until 22 min)
    // — the route for that trip showed a jittery loop right at home, i.e.
    // exactly this kind of noise repeatedly re-triggering reset().
    //
    // The maxRadius check below is the actual authoritative signal: it's
    // computed from a rolling window of multiple real fixes (centroid +
    // radius), so a single noisy/laggy point barely moves it, while
    // genuine sustained movement still grows the radius past stopRadius
    // and resets correctly on its own — no separate instantaneous veto
    // needed.
    _window.add(pos);
    if (_window.length > 30) _window.removeAt(0);
    _windowStart ??= pos.timestamp;

    if (_window.length < 3) return false;

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

    if (maxRadius > stopRadius) {
      reset();
      return false;
    }

    final duration = pos.timestamp.difference(_windowStart!).inSeconds;

    if (duration >= stopDuration && !_stopped) {
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
    final lng = pts.map((p) => p.longitude).reduce((a, b) => a + b) / pts.length;
    return (lat, lng);
  }
}
