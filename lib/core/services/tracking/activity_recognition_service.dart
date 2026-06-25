import 'dart:async';
import 'package:activity_recognition_flutter/activity_recognition_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:child_track/core/utils/structured_logger.dart';

// ── Activity types ──────────────────────────────────────────────────────────

enum NaviQActivityType {
  walking,
  running,
  cycling,
  vehicle,
  stationary,
  unknown,
}

class ActivityState {
  final NaviQActivityType type;

  /// 0.0–1.0 confidence from the underlying platform API.
  final double confidence;

  final DateTime timestamp;

  const ActivityState({
    required this.type,
    required this.confidence,
    required this.timestamp,
  });

  bool get isMoving => type != NaviQActivityType.stationary &&
      type != NaviQActivityType.unknown;

  @override
  String toString() =>
      'ActivityState(${type.name}, conf: ${(confidence * 100).toStringAsFixed(0)}%)';
}

// ── Service ─────────────────────────────────────────────────────────────────

/// Wraps the platform Activity Recognition API (Android ActivityRecognition /
/// iOS CoreMotion) and exposes a unified [ActivityState] stream.
class ActivityRecognitionService {
  static final ActivityRecognitionService _instance =
      ActivityRecognitionService._internal();
  factory ActivityRecognitionService() => _instance;
  ActivityRecognitionService._internal();

  final ActivityRecognition _ar = ActivityRecognition();
  StreamSubscription<ActivityEvent>? _subscription;
  ActivityState _lastActivity = ActivityState(
    type: NaviQActivityType.unknown,
    confidence: 0.0,
    timestamp: DateTime.now(),
  );

  bool _useFallback = false;
  final _controller = StreamController<ActivityState>.broadcast();

  Stream<ActivityState> get stream => _controller.stream;
  ActivityState get current => _lastActivity;
  bool get isUsingFallback => _useFallback;

  /// Start listening. Safe to call multiple times.
  Future<void> start() async {
    if (_subscription != null) return;
    try {
      final status = await Permission.activityRecognition.status;
      if (status.isGranted) {
        _useFallback = false;
        _subscription = _ar
            .activityStream(runForegroundService: false)
            .listen(_onEvent, onError: _onError);
        StructuredLogger.log(LogTag.BG, '[AR] Activity recognition started');
      } else {
        // Try to request
        final requestStatus = await Permission.activityRecognition.request();
        if (requestStatus.isGranted) {
          _useFallback = false;
          _subscription = _ar
              .activityStream(runForegroundService: false)
              .listen(_onEvent, onError: _onError);
          StructuredLogger.log(LogTag.BG, '[AR] Activity recognition started after request');
        } else {
          _useFallback = true;
          StructuredLogger.log(LogTag.BG, '[AR] Permission denied. Falling back to GPS classification.');
        }
      }
    } catch (e) {
      _useFallback = true;
      StructuredLogger.log(LogTag.BG, '[AR] Failed to start activity recognition, using GPS fallback', error: e);
    }
  }

  /// Request permission, with redirect to settings if permanently denied
  Future<bool> requestPermission() async {
    try {
      final status = await Permission.activityRecognition.status;
      if (status.isGranted) {
        return true;
      }
      final requestStatus = await Permission.activityRecognition.request();
      if (requestStatus.isGranted) {
        return true;
      }
      if (requestStatus.isPermanentlyDenied) {
        await openAppSettings();
      }
      return false;
    } catch (e) {
      StructuredLogger.log(LogTag.BG, '[AR] Error requesting permission', error: e);
      return false;
    }
  }

  /// Fallback mode classification based on GPS speed (m/s)
  void updateSpeedFallback(double speedMps) {
    if (!_useFallback) return;
    
    NaviQActivityType type;
    if (speedMps < 0.5) {
      type = NaviQActivityType.stationary;
    } else if (speedMps < 2.5) {
      type = NaviQActivityType.walking;
    } else if (speedMps < 6.0) {
      type = NaviQActivityType.cycling;
    } else {
      type = NaviQActivityType.vehicle;
    }
    
    final state = ActivityState(
      type: type,
      confidence: 0.7, // Moderate confidence from GPS speed
      timestamp: DateTime.now(),
    );
    
    // Only update if type changed or it's been more than 10 seconds since last update
    if (_lastActivity.type != type || 
        DateTime.now().difference(_lastActivity.timestamp).inSeconds > 10) {
      _lastActivity = state;
      _controller.add(state);
      StructuredLogger.log(
        LogTag.BG,
        '[AR-Fallback] $state derived from speed: ${(speedMps * 3.6).toStringAsFixed(1)} km/h',
      );
    }
  }

  void stop() {
    _subscription?.cancel();
    _subscription = null;
    StructuredLogger.log(LogTag.BG, '[AR] Activity recognition stopped');
  }

  void dispose() {
    stop();
    _controller.close();
  }

  void _onEvent(ActivityEvent event) {
    final type = _mapType(event.type);
    final confidence = _mapConfidence(event.confidence);
    final state = ActivityState(
      type: type,
      confidence: confidence,
      timestamp: DateTime.now(),
    );
    _lastActivity = state;
    _controller.add(state);
    StructuredLogger.log(
      LogTag.BG,
      '[AR] $state ← ${event.type.name}(${event.confidence}%)',
    );
  }

  void _onError(Object e) {
    StructuredLogger.log(LogTag.BG, '[AR] Stream error', error: e);
  }

  static NaviQActivityType _mapType(ActivityType raw) {
    switch (raw) {
      case ActivityType.inVehicle:
        return NaviQActivityType.vehicle;
      case ActivityType.onBicycle:
        return NaviQActivityType.cycling;
      case ActivityType.running:
        return NaviQActivityType.running;
      case ActivityType.walking:
      case ActivityType.onFoot:
        return NaviQActivityType.walking;
      case ActivityType.still:
        return NaviQActivityType.stationary;
      case ActivityType.tilting:
      case ActivityType.unknown:
      default:
        return NaviQActivityType.unknown;
    }
  }

  static double _mapConfidence(int raw) {
    return raw / 100.0;
  }
}
