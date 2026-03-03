import 'dart:async';
import 'package:battery_plus/battery_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:child_track/core/utils/structured_logger.dart';
import 'package:child_track/app/childapp/view_model/repository/child_repo.dart';
import 'package:child_track/app/childapp/view_model/repository/child_location_repo.dart';
import 'package:child_track/core/services/shared_prefs_service.dart';

/// Trip mode detected from movement patterns.
enum BgTripMode { unknown, walking, vehicle }

/// Internal state of the background location state machine.
enum BgTripState { idle, candidate, tracking }

/// Mirrors the ChildBloc location-posting + trip-detection logic so that
/// the background service behaves identically when the app is killed or
/// minimised.
class LocationStateMachine {
  // ── Dependencies ──────────────────────────────────────────────────────
  final ChildRepo _childRepo;
  final ChildGoogleMapsRepo _locationRepo;
  final SharedPrefsService _prefs;
  final Battery _battery;

  // ── Location posting state ────────────────────────────────────────────
  Position? _lastPostedLocation;

  // ── Trip detection state (mirrors ChildBloc._processTripStartLogic) ──
  BgTripState _state = BgTripState.idle;
  List<Position> _candidatePoints = [];

  // ── Trip tracking state (mirrors ChildBloc._onUpdateTripLocation) ────
  bool _isTripTracking = false;
  BgTripMode _tripMode = BgTripMode.unknown;

  LocationStateMachine({
    required ChildRepo childRepo,
    required ChildGoogleMapsRepo locationRepo,
    required SharedPrefsService prefs,
    Battery? battery,
  }) : _childRepo = childRepo,
       _locationRepo = locationRepo,
       _prefs = prefs,
       _battery = battery ?? Battery();

  // ════════════════════════════════════════════════════════════════════════
  // PUBLIC: called by BackgroundLocationService on every location update
  // ════════════════════════════════════════════════════════════════════════

  /// Main entry – mirrors ChildBloc._onGetChildLocation
  Future<void> processLocation(Position position) async {
    StructuredLogger.log(
      LogTag.BG,
      'Processing: ${position.latitude},${position.longitude} '
      '| Spd: ${position.speed.toStringAsFixed(2)} '
      '| Acc: ${position.accuracy.toStringAsFixed(1)}',
    );

    final childId = _prefs.getString('child_id');
    if (childId == null || childId.isEmpty) {
      StructuredLogger.log(LogTag.BG, 'No child_id – skipping');
      return;
    }

    // ── 10 m distance gate (same as ChildBloc) ──────────────────────────
    double distance = 0.0;
    if (_lastPostedLocation != null) {
      distance = Geolocator.distanceBetween(
        _lastPostedLocation!.latitude,
        _lastPostedLocation!.longitude,
        position.latitude,
        position.longitude,
      );
    }

    StructuredLogger.log(
      LogTag.BG,
      'Distance from last posted: ${distance.toStringAsFixed(1)} m',
    );

    if (_lastPostedLocation == null || distance >= 10) {
      _lastPostedLocation = position;

      // Post plain location (mirrors _onPostChildLocation)
      await _postChildLocation(position, childId);

      // Trip logic
      if (_isTripTracking) {
        await _updateTripLocation(position, childId);
      } else {
        await _processTripStartLogic(position, childId);
      }
    }
  }

  // ════════════════════════════════════════════════════════════════════════
  // LOCATION POSTING  (mirrors ChildBloc._onPostChildLocation)
  // ════════════════════════════════════════════════════════════════════════

  Future<void> _postChildLocation(Position pos, String childId) async {
    try {
      final locationInfo = await _locationRepo.getAddressAndPlaceName(
        pos.latitude,
        pos.longitude,
      );

      final requestBody = {
        "address": locationInfo?['address'] ?? locationInfo?.values.first,
        "place_name": locationInfo?['place_name'] ?? locationInfo?.values.last,
        "child_id": childId,
        "lat": pos.latitude,
        "lng": pos.longitude,
        "accuracy_m": pos.accuracy,
        "speed_mps": pos.speed,
        "bearing": pos.heading,
        "timestamp": DateTime.now().toUtc().toIso8601String(),
      };

      StructuredLogger.log(LogTag.BG, 'Posting location → $requestBody');
      final response = await _childRepo.postChildLocation(requestBody);
      StructuredLogger.log(
        LogTag.BG,
        'Location post response: [${response.statusCode}] ${response.message}',
      );
    } catch (e) {
      StructuredLogger.log(LogTag.BG, 'Failed to post location', error: e);
    }
  }

  // ════════════════════════════════════════════════════════════════════════
  // TRIP DETECTION  (mirrors ChildBloc._processTripStartLogic exactly)
  // ════════════════════════════════════════════════════════════════════════

  Future<void> _processTripStartLogic(Position location, String childId) async {
    // 1. FILTER NOISE
    if (location.accuracy > 30.0) {
      StructuredLogger.log(
        LogTag.TRIP,
        'Ignored poor accuracy point (${location.accuracy}m)',
      );
      return;
    }

    // 2. SLIDING WINDOW MANAGEMENT
    List<Position> newWindow = List.from(_candidatePoints);
    newWindow.add(location);

    // Keep last 15 points max
    if (newWindow.length > 15) {
      newWindow.removeAt(0);
    }

    // 3. CHECK FOR RESET (TIMEOUT)
    if (newWindow.isNotEmpty && newWindow.length > 1) {
      final lastPoint = newWindow.last;
      final prevPoint = newWindow[newWindow.length - 2];
      final gap = lastPoint.timestamp.difference(prevPoint.timestamp).inSeconds;
      if (gap > 300) {
        StructuredLogger.log(
          LogTag.TRIP,
          'Gap too large ($gap s), resetting window',
        );
        newWindow = [location];
      }
    }

    // 4. ANALYZE WINDOW SIGNALS
    if (newWindow.length < 3) {
      _candidatePoints = newWindow;
      _state = BgTripState.candidate;
      return;
    }

    // Calculate Metrics
    double totalDistance = 0;
    for (int i = 0; i < newWindow.length - 1; i++) {
      totalDistance += Geolocator.distanceBetween(
        newWindow[i].latitude,
        newWindow[i].longitude,
        newWindow[i + 1].latitude,
        newWindow[i + 1].longitude,
      );
    }

    final startPoint = newWindow.first;
    final endPoint = newWindow.last;
    final straightDist = Geolocator.distanceBetween(
      startPoint.latitude,
      startPoint.longitude,
      endPoint.latitude,
      endPoint.longitude,
    );

    final durationSeconds = endPoint.timestamp
        .difference(startPoint.timestamp)
        .inSeconds;

    if (durationSeconds < 1) return;

    final avgSpeed = totalDistance / durationSeconds;
    final consistencyRatio = totalDistance > 0
        ? straightDist / totalDistance
        : 0.0;

    StructuredLogger.log(
      LogTag.TRIP,
      'Window=${newWindow.length} pts, Dur=${durationSeconds}s, '
      'Dist=${totalDistance.toStringAsFixed(1)}m, '
      'Speed=${avgSpeed.toStringAsFixed(1)}m/s, '
      'Consistency=${consistencyRatio.toStringAsFixed(2)}',
    );

    // 5. DETERMINE MODE & CHECK RULES
    BgTripMode? estimatedMode;
    bool rulesMet = false;

    // Walking: > 30m, Speed 0.6-1.8 m/s, Duration > 30s
    if (avgSpeed >= 0.6 && avgSpeed <= 1.8) {
      if (totalDistance >= 30 && durationSeconds >= 30) {
        estimatedMode = BgTripMode.walking;
        rulesMet = true;
      }
    }
    // Cycling/Running: > 60m, Speed 1.8-5.0 m/s
    else if (avgSpeed > 1.8 && avgSpeed <= 5.0) {
      if (totalDistance >= 60 && durationSeconds >= 20) {
        estimatedMode = BgTripMode.vehicle;
        rulesMet = true;
      }
    }
    // Vehicle: > 100m, Speed > 5.0 m/s
    else if (avgSpeed > 5.0) {
      if (totalDistance >= 100 && durationSeconds >= 20) {
        estimatedMode = BgTripMode.vehicle;
        rulesMet = true;
      }
    }

    // 6. DIRECTION CONSISTENCY CHECK
    if (rulesMet && consistencyRatio < 0.6) {
      StructuredLogger.log(
        LogTag.TRIP,
        'Rejected – low consistency ($consistencyRatio)',
      );
      rulesMet = false;
    }

    // 7. DECISION
    if (rulesMet && estimatedMode != null) {
      StructuredLogger.log(LogTag.TRIP, 'TRIP CONFIRMED! Mode: $estimatedMode');
      await _startTripTracking(estimatedMode, childId);
    } else {
      _candidatePoints = newWindow;
      _state = BgTripState.candidate;
    }
  }

  // ════════════════════════════════════════════════════════════════════════
  // TRIP TRACKING  (mirrors ChildBloc._onStartTripTracking / Stop / Update)
  // ════════════════════════════════════════════════════════════════════════

  Future<void> _startTripTracking(BgTripMode mode, String childId) async {
    _isTripTracking = true;
    _tripMode = mode;
    _state = BgTripState.tracking;

    // Instead of discarding the history that built this trip, post it all as the initial trip data
    final pointsToPost = List<Position>.from(_candidatePoints);
    _candidatePoints = [];

    StructuredLogger.log(LogTag.STATE, 'Trip tracking STARTED (mode: $mode)');

    if (pointsToPost.isNotEmpty) {
      await _postTripBatch(pointsToPost, childId);
    }
  }

  void _stopTripTracking() {
    _isTripTracking = false;
    _tripMode = BgTripMode.unknown;
    _state = BgTripState.idle;
    _candidatePoints = [];

    StructuredLogger.log(LogTag.STATE, 'Trip tracking STOPPED – state reset');
  }

  /// Post a single trip location point
  Future<void> _updateTripLocation(Position pos, String childId) async {
    await _postTripBatch([pos], childId);
  }

  /// Bulk-post an array of locations to the backend trip tracking endpoint
  Future<void> _postTripBatch(List<Position> points, String childId) async {
    if (points.isEmpty) return;

    try {
      int batteryLevel = 0;
      try {
        batteryLevel = await _battery.batteryLevel;
      } catch (_) {}

      final formattedPoints = points
          .map(
            (pos) => {
              "lat": pos.latitude,
              "lng": pos.longitude,
              "speed": pos.speed,
              "accuracy": pos.accuracy,
              "ts": pos.timestamp.toUtc().toIso8601String(),
              "battery": batteryLevel,
            },
          )
          .toList();

      final requestBody = {"points": formattedPoints};

      StructuredLogger.log(
        LogTag.TRIP,
        'Posting trip locations (${points.length} pts) → $requestBody',
      );

      final response = await _childRepo.postTripLocation(
        childId: childId,
        data: requestBody,
      );

      StructuredLogger.log(
        LogTag.TRIP,
        'Trip location response: ${response.data}',
      );

      if (response.isSuccess && response.data != null) {
        if (_shouldStopTrip(response.data)) {
          StructuredLogger.log(
            LogTag.TRIP,
            'Backend requested STOP – ending trip',
          );
          _stopTripTracking();
        }
      }
    } catch (e) {
      StructuredLogger.log(
        LogTag.TRIP,
        'Failed to post trip locations',
        error: e,
      );
    }
  }

  /// Mirrors ChildBloc._shouldStopTrip exactly
  bool _shouldStopTrip(dynamic responseData) {
    if (responseData == null) return false;

    try {
      final currentState = responseData['currentState'];
      if (currentState != 'IDLE') return false;

      final transitions = responseData['stateTransitions'];
      if (transitions is List && transitions.isNotEmpty) {
        for (var transition in transitions) {
          if (transition['to'] == 'ENDED' &&
              transition['reason'] == 'STATIONARY_CONFIRMED') {
            return true;
          }
        }
      }
    } catch (e) {
      StructuredLogger.log(
        LogTag.TRIP,
        'Error parsing stop-trip response',
        error: e,
      );
    }

    return false;
  }

  // ── Getters for notification display ──────────────────────────────────
  bool get isTripTracking => _isTripTracking;
  BgTripMode get tripMode => _tripMode;
  BgTripState get currentState => _state;
}
