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
    }
  }
}

class TimelineEngine {
  static const double _stopSpeedMs = 0.5;
  static const int _stopMinSeconds = 60;

  static List<TimelineEvent> generate({
    required List<Map<String, dynamic>> points,
    String initialRideMode = 'vehicle',
  }) {
    if (points.isEmpty) return [];

    final events = <TimelineEvent>[];
    NaviQActivityType? lastMode;
    int stopStartIdx = -1;
    double cumulativeDistKm = 0;

    final first = points.first;
    events.add(TimelineEvent(
      type: TimelineEventType.tripStart,
      time: _parseTs(first['ts']),
      label: 'Trip Started',
      lat: safeToDouble(first['lat']),
      lng: safeToDouble(first['lng']),
    ));

    lastMode = _modeFromString(initialRideMode);
    events.add(_modeEvent(lastMode, _parseTs(first['ts']), distanceKm: 0));

    for (int i = 1; i < points.length; i++) {
      final pt = points[i];
      final prev = points[i - 1];

      final speed = safeToDouble(pt['speed']);
      final lat = safeToDouble(pt['lat']);
      final lng = safeToDouble(pt['lng']);
      final ts = _parseTs(pt['ts']);

      final segDist = Geolocator.distanceBetween(
        safeToDouble(prev['lat']),
        safeToDouble(prev['lng']),
        lat,
        lng,
      );
      cumulativeDistKm += segDist / 1000;

      final mode = _modeFromSpeed(speed);

      if (mode != lastMode && mode != NaviQActivityType.unknown) {
        if (lastMode == NaviQActivityType.stationary && stopStartIdx != -1) {
          final stopStart = _parseTs(points[stopStartIdx]['ts']);
          final stopDur = ts.difference(stopStart);
          if (stopDur.inSeconds >= _stopMinSeconds) {
            events.add(TimelineEvent(
              type: TimelineEventType.stopped,
              time: stopStart,
              label: 'Stopped for ${_formatDuration(stopDur)}',
              lat: lat,
              lng: lng,
              stopDuration: stopDur,
            ));
          }
          stopStartIdx = -1;
        }

        events.add(_modeEvent(mode, ts, distanceKm: cumulativeDistKm));
        lastMode = mode;
      }

      if (speed < _stopSpeedMs && stopStartIdx == -1) {
        stopStartIdx = i;
      } else if (speed >= _stopSpeedMs) {
        stopStartIdx = -1;
      }
    }

    events.sort((a, b) => a.time.compareTo(b.time));

    return events;
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
      default:
        return NaviQActivityType.vehicle;
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
