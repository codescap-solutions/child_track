import 'package:geolocator/geolocator.dart';
import 'package:child_track/core/services/tracking/activity_recognition_service.dart';
import 'package:child_track/core/utils/parser_utils.dart';

enum TimelineEventType {
  tripStart,
  startedWalking,
  startedRunning,
  startedCycling,
  startedVehicle,
  stopped,
  arrived,
  leftPlace,
  geofenceEntered,
  geofenceExited,
  lostLocation,
}

class TimelineEvent {
  final TimelineEventType type;
  final DateTime time;
  final String label;
  final double? lat;
  final double? lng;
  final String? placeName;
  final Duration? stopDuration;
  final double? speedKmh;
  final double? distanceKm;

  const TimelineEvent({
    required this.type,
    required this.time,
    required this.label,
    this.lat,
    this.lng,
    this.placeName,
    this.stopDuration,
    this.speedKmh,
    this.distanceKm,
  });

  String get icon {
    switch (type) {
      case TimelineEventType.tripStart:
        return '🚀';
      case TimelineEventType.startedWalking:
        return '🚶';
      case TimelineEventType.startedRunning:
        return '🏃';
      case TimelineEventType.startedCycling:
        return '🚴';
      case TimelineEventType.startedVehicle:
        return '🚗';
      case TimelineEventType.stopped:
        return '⏸';
      case TimelineEventType.arrived:
        return '📍';
      case TimelineEventType.leftPlace:
        return '👋';
      case TimelineEventType.geofenceEntered:
        return '🔔';
      case TimelineEventType.geofenceExited:
        return '🔕';
      case TimelineEventType.lostLocation:
        return '⚠️';
    }
  }
}

class TimelineEngine {
  static const double _stopSpeedMs = 0.5;
  static const int _stopMinSeconds = 60;

  // Runs shorter than this are noise (a couple of points misread during
  // ordinary walking-pace GPS speed jitter, not a real activity change) and
  // get absorbed into a neighboring run instead of becoming their own
  // "Started X" timeline entry. Mirrors the equivalent server-side fix in
  // naviQ-server's mergeAndCleanSegments.
  static const int _minRunSeconds = 60;

  static List<TimelineEvent> generate({
    required List<Map<String, dynamic>> points,
    String initialRideMode = 'stationary',
  }) {
    if (points.isEmpty) return [];

    final events = <TimelineEvent>[];
    final first = points.first;
    events.add(TimelineEvent(
      type: TimelineEventType.tripStart,
      time: _parseTs(first['ts']),
      label: 'Trip Started',
      lat: safeToDouble(first['lat']),
      lng: safeToDouble(first['lng']),
    ));

    // 1. Classify every point's raw instantaneous mode + running distance.
    final rawModes = <NaviQActivityType>[];
    final cumDistKm = <double>[0.0];
    for (int i = 0; i < points.length; i++) {
      rawModes.add(_modeFromSpeed(safeToDouble(points[i]['speed'])));
      if (i > 0) {
        final segDist = Geolocator.distanceBetween(
          safeToDouble(points[i - 1]['lat']),
          safeToDouble(points[i - 1]['lng']),
          safeToDouble(points[i]['lat']),
          safeToDouble(points[i]['lng']),
        );
        cumDistKm.add(cumDistKm.last + segDist / 1000);
      }
    }

    // 2. Group into raw consecutive-same-mode runs, then absorb any run
    // shorter than _minRunSeconds into whichever neighbor is longer —
    // without this, a single noisy point (or a couple in a row) reading a
    // different instantaneous speed flips `mode` and fires a brand new
    // "Started Walking"/stop event on nearly every point, instead of once
    // per real, sustained activity change.
    var runs = _groupIntoRuns(points, rawModes);
    for (int pass = 0; pass < 5; pass++) {
      if (runs.length <= 1) break;
      final absorbed = _absorbShortRuns(points, runs);
      if (absorbed == null) break; // nothing left to absorb — stable
      runs = _collapseAdjacentRuns(absorbed);
    }

    // 3. Emit timeline events from the cleaned runs.
    NaviQActivityType lastMode = _modeFromString(initialRideMode);
    events.add(_modeEvent(lastMode, _parseTs(first['ts']), distanceKm: 0));

    for (int i = 0; i < runs.length; i++) {
      final run = runs[i];
      if (run.mode == lastMode) continue;

      final ts = _parseTs(points[run.startIdx]['ts']);

      if (lastMode == NaviQActivityType.stationary && i > 0) {
        final prevRun = runs[i - 1];
        final stopStart = _parseTs(points[prevRun.startIdx]['ts']);
        final stopDur = ts.difference(stopStart);
        if (stopDur.inSeconds >= _stopMinSeconds) {
          events.add(TimelineEvent(
            type: TimelineEventType.stopped,
            time: stopStart,
            label: 'Stopped for ${_formatDuration(stopDur)}',
            lat: safeToDouble(points[prevRun.startIdx]['lat']),
            lng: safeToDouble(points[prevRun.startIdx]['lng']),
            stopDuration: stopDur,
          ));
        }
      }

      events.add(_modeEvent(run.mode, ts, distanceKm: cumDistKm[run.startIdx]));
      lastMode = run.mode;
    }

    events.sort((a, b) => a.time.compareTo(b.time));

    return events;
  }

  static List<_ModeRun> _groupIntoRuns(
    List<Map<String, dynamic>> points,
    List<NaviQActivityType> rawModes,
  ) {
    final runs = <_ModeRun>[];
    var runStart = 0;
    for (int i = 1; i <= points.length; i++) {
      if (i == points.length || rawModes[i] != rawModes[runStart]) {
        runs.add(_ModeRun(mode: rawModes[runStart], startIdx: runStart, endIdx: i - 1));
        runStart = i;
      }
    }
    return runs;
  }

  static int _runDurationSeconds(List<Map<String, dynamic>> points, _ModeRun run) {
    return _parseTs(points[run.endIdx]['ts'])
        .difference(_parseTs(points[run.startIdx]['ts']))
        .inSeconds;
  }

  /// Returns a retyped run list with short runs relabeled to match whichever
  /// neighbor is longer, or null if none were short enough to need it.
  static List<_ModeRun>? _absorbShortRuns(
    List<Map<String, dynamic>> points,
    List<_ModeRun> runs,
  ) {
    var anyShort = false;
    final retyped = <_ModeRun>[];
    for (int i = 0; i < runs.length; i++) {
      final run = runs[i];
      if (_runDurationSeconds(points, run) >= _minRunSeconds) {
        retyped.add(run);
        continue;
      }
      final prev = i > 0 ? runs[i - 1] : null;
      final next = i < runs.length - 1 ? runs[i + 1] : null;
      if (prev == null && next == null) {
        retyped.add(run);
        continue;
      }
      NaviQActivityType absorbMode;
      if (prev != null && next != null) {
        absorbMode = _runDurationSeconds(points, prev) >= _runDurationSeconds(points, next)
            ? prev.mode
            : next.mode;
      } else {
        absorbMode = prev?.mode ?? next!.mode;
      }
      anyShort = true;
      retyped.add(_ModeRun(mode: absorbMode, startIdx: run.startIdx, endIdx: run.endIdx));
    }
    return anyShort ? retyped : null;
  }

  static List<_ModeRun> _collapseAdjacentRuns(List<_ModeRun> runs) {
    final collapsed = <_ModeRun>[];
    for (final run in runs) {
      if (collapsed.isNotEmpty && collapsed.last.mode == run.mode) {
        collapsed[collapsed.length - 1] =
            _ModeRun(mode: run.mode, startIdx: collapsed.last.startIdx, endIdx: run.endIdx);
      } else {
        collapsed.add(run);
      }
    }
    return collapsed;
  }

  static TimelineEvent _modeEvent(
    NaviQActivityType mode,
    DateTime time, {
    required double distanceKm,
  }) {
    switch (mode) {
      case NaviQActivityType.walking:
        return TimelineEvent(
          type: TimelineEventType.startedWalking,
          time: time,
          label: 'Started Walking',
          distanceKm: distanceKm,
        );
      case NaviQActivityType.running:
        return TimelineEvent(
          type: TimelineEventType.startedRunning,
          time: time,
          label: 'Started Running',
          distanceKm: distanceKm,
        );
      case NaviQActivityType.cycling:
        return TimelineEvent(
          type: TimelineEventType.startedCycling,
          time: time,
          label: 'Started Cycling',
          distanceKm: distanceKm,
        );
      case NaviQActivityType.vehicle:
        return TimelineEvent(
          type: TimelineEventType.startedVehicle,
          time: time,
          label: 'In Vehicle',
          distanceKm: distanceKm,
        );
      default:
        return TimelineEvent(
          type: TimelineEventType.stopped,
          time: time,
          label: 'Stationary',
          distanceKm: distanceKm,
        );
    }
  }

  static NaviQActivityType _modeFromSpeed(double speedMs) {
    if (speedMs < _stopSpeedMs) return NaviQActivityType.stationary;
    if (speedMs < 2.0) return NaviQActivityType.walking;
    if (speedMs < 4.0) return NaviQActivityType.running;
    if (speedMs < 8.0) return NaviQActivityType.cycling;
    return NaviQActivityType.vehicle;
  }

  static NaviQActivityType _modeFromString(String mode) {
    switch (mode.toLowerCase()) {
      case 'walking':
        return NaviQActivityType.walking;
      case 'running':
        return NaviQActivityType.running;
      case 'cycling':
        return NaviQActivityType.cycling;
      case 'vehicle':
        return NaviQActivityType.vehicle;
      case 'stationary':
        return NaviQActivityType.stationary;
      default:
        // Was NaviQActivityType.vehicle — meant a trip whose real mode was
        // "stationary" (or simply missing/unrecognized) rendered as "In
        // Vehicle" on the timeline. Stationary is the safe/neutral default:
        // it renders as "Stationary" rather than falsely implying a ride.
        return NaviQActivityType.stationary;
    }
  }

  static DateTime _parseTs(dynamic ts) {
    try {
      return DateTime.parse(ts.toString()).toLocal();
    } catch (_) {
      return DateTime.now();
    }
  }

  static String _formatDuration(Duration d) {
    if (d.inHours > 0) {
      return '${d.inHours}h ${d.inMinutes.remainder(60)}m';
    }
    return '${d.inMinutes}m';
  }
}

/// A run of consecutive points sharing the same raw activity mode, by index
/// range into the original points list (inclusive).
class _ModeRun {
  final NaviQActivityType mode;
  final int startIdx;
  final int endIdx;

  _ModeRun({required this.mode, required this.startIdx, required this.endIdx});
}
