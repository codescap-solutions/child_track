import 'dart:async';
import 'package:battery_plus/battery_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:child_track/core/utils/structured_logger.dart';
import 'package:child_track/app/childapp/view_model/repository/child_repo.dart';
import 'package:child_track/app/childapp/view_model/repository/child_location_repo.dart';
import 'package:child_track/core/services/shared_prefs_service.dart';
import 'package:child_track/app/childapp/view_model/repository/device_info_service.dart';
import 'package:child_track/core/services/tracking/enhanced_trip_point.dart';
import 'package:child_track/core/services/tracking/activity_recognition_service.dart';
import 'package:child_track/core/services/tracking/trip_classification_engine.dart';
import 'package:child_track/core/services/tracking/stop_detection_service.dart';
import 'package:child_track/core/services/tracking/offline_trip_queue.dart';
import 'package:child_track/core/services/tracking/local_geofence_engine.dart';

export 'package:child_track/core/services/tracking/trip_classification_engine.dart'
    show BgTripMode;

/// Internal state of the trip state machine.
enum BgTripState { idle, candidate, tracking }

/// Enhanced LocationStateMachine — integrates:
///   • EnhancedTripPoint (full GPS metadata)
///   • ActivityRecognitionService (AR-fused mode detection)
///   • TripClassificationEngine (hybrid confidence scoring)
///   • StopDetectionService (local stop without server dependency)
///   • OfflineTripQueue (connectivity-failure recovery)
///   • LocalGeofenceEngine (immediate geofence events)
class LocationStateMachine {
  // ── Dependencies ──────────────────────────────────────────────────────────
  final ChildRepo _childRepo;
  final ChildGoogleMapsRepo _locationRepo;
  final SharedPrefsService _prefs;
  final Battery _battery;

  // ── New services ──────────────────────────────────────────────────────────
  final ActivityRecognitionService _ar = ActivityRecognitionService();
  final TripClassificationEngine _classifier = TripClassificationEngine();
  final StopDetectionService _stopDetector = StopDetectionService();
  final OfflineTripQueue _offlineQueue = OfflineTripQueue();
  final LocalGeofenceEngine _geoEngine = LocalGeofenceEngine();

  StreamSubscription<StopEvent>? _stopSub;

  // ── State ─────────────────────────────────────────────────────────────────
  Position? _lastPostedLocation;
  BgTripState _state = BgTripState.idle;
  List<Position> _candidatePoints = [];
  bool _isTripTracking = false;
  BgTripMode _tripMode = BgTripMode.unknown;

  // Pending offline drain cooldown
  DateTime? _lastDrainAttempt;

  LocationStateMachine({
    required ChildRepo childRepo,
    required ChildGoogleMapsRepo locationRepo,
    required SharedPrefsService prefs,
    Battery? battery,
  }) : _childRepo = childRepo,
       _locationRepo = locationRepo,
       _prefs = prefs,
       _battery = battery ?? Battery() {
    // Start activity recognition
    _ar.start();

    // Listen for local stop events
    _stopSub = _stopDetector.onStop.listen(_onLocalStopDetected);

    // Load offline queue
    _offlineQueue.load();
  }

  void dispose() {
    _ar.stop();
    _stopSub?.cancel();
    _stopDetector.dispose();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // PUBLIC ENTRY POINT
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> processLocation(Position position) async {
    StructuredLogger.log(
      LogTag.BG,
      'Processing: ${position.latitude},${position.longitude} '
      '| Spd: ${(position.speed * 3.6).toStringAsFixed(1)} km/h '
      '| Acc: ${position.accuracy.toStringAsFixed(1)}m '
      '| Bearing: ${position.heading.toStringAsFixed(0)}°',
    );

    final childId = _prefs.getString('child_id');
    if (childId == null || childId.isEmpty) {
      StructuredLogger.log(LogTag.BG, 'No child_id – skipping');
      return;
    }

    // ── Distance gate (adaptive — respects current profile filter) ──────────
    double distance = 0.0;
    if (_lastPostedLocation != null) {
      distance = Geolocator.distanceBetween(
        _lastPostedLocation!.latitude,
        _lastPostedLocation!.longitude,
        position.latitude,
        position.longitude,
      );
    }

    if (_lastPostedLocation != null && distance < 5) {
      StructuredLogger.log(
        LogTag.BG,
        'Skipped (${distance.toStringAsFixed(1)}m < 5m filter)',
      );
      return;
    }

    _lastPostedLocation = position;

    // ── Local geofence check (immediate, no HTTP) ──────────────────────────
    _geoEngine.processPosition(position.latitude, position.longitude);

    // ── Stop detection ─────────────────────────────────────────────────────
    _ar.updateSpeedFallback(position.speed);
    _stopDetector.processPosition(position, _ar.current);

    // ── Post plain location ────────────────────────────────────────────────
    await _postChildLocation(position, childId);

    // ── Trip logic ─────────────────────────────────────────────────────────
    if (_isTripTracking) {
      await _updateTripLocation(position, childId);
    } else {
      await _processTripStartLogic(position, childId);
    }

    // ── Drain offline queue if online ──────────────────────────────────────
    _tryDrainOfflineQueue(childId);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // LOCATION POSTING
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> _postChildLocation(Position pos, String childId) async {
    try {
      final locationInfo = await _locationRepo.getAddressAndPlaceName(
        pos.latitude,
        pos.longitude,
      );

      final requestBody = {
        'address': locationInfo?['address'] ?? locationInfo?.values.first,
        'place_name':
            locationInfo?['place_name'] ?? locationInfo?.values.last,
        'child_id': childId,
        'lat': pos.latitude,
        'lng': pos.longitude,
        'accuracy_m': pos.accuracy,
        'speed_mps': pos.speed < 0 ? 0.0 : pos.speed,
        'bearing': pos.heading < 0 ? 0.0 : pos.heading,
        'altitude': pos.altitude,
        'speed_accuracy': pos.speedAccuracy,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      };

      StructuredLogger.log(LogTag.BG, 'Posting location → $requestBody');
      final response = await _childRepo.postChildLocation(requestBody);
      StructuredLogger.log(
        LogTag.BG,
        'Location post: [${response.statusCode}] ${response.message}',
      );
    } catch (e) {
      StructuredLogger.log(LogTag.BG, 'Failed to post location', error: e);
      // Offline queue for location updates
      try {
        final int battery = await _battery.batteryLevel;
        await _offlineQueue.enqueueLocation(
          childId: childId,
          payload: {
            'lat': pos.latitude,
            'lng': pos.longitude,
            'accuracy_m': pos.accuracy,
            'speed_mps': pos.speed < 0 ? 0.0 : pos.speed,
            'bearing': pos.heading < 0 ? 0.0 : pos.heading,
            'timestamp': DateTime.now().toUtc().toIso8601String(),
            'battery': battery,
          },
        );
      } catch (_) {}
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // TRIP START DETECTION  (hybrid — GPS + AR + heading)
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> _processTripStartLogic(Position location, String childId) async {
    // Filter poor GPS
    if (location.accuracy > 30.0) {
      StructuredLogger.log(
        LogTag.TRIP,
        'Ignored poor accuracy (${location.accuracy}m)',
      );
      return;
    }

    // Hybrid classification
    final classification = _classifier.classify(
      position: location,
      arState: _ar.current,
    );

    // Sliding window
    List<Position> newWindow = List.from(_candidatePoints)..add(location);
    if (newWindow.length > 15) newWindow.removeAt(0);

    // Gap reset
    if (newWindow.length > 1) {
      final gap = newWindow.last.timestamp
          .difference(newWindow[newWindow.length - 2].timestamp)
          .inSeconds;
      if (gap > 300) {
        StructuredLogger.log(LogTag.TRIP, 'Gap $gap s – resetting window');
        newWindow = [location];
      }
    }

    if (newWindow.length < 3) {
      _candidatePoints = newWindow;
      _state = BgTripState.candidate;
      return;
    }

    // Metrics over window
    double totalDistance = 0;
    for (int i = 0; i < newWindow.length - 1; i++) {
      totalDistance += Geolocator.distanceBetween(
        newWindow[i].latitude, newWindow[i].longitude,
        newWindow[i + 1].latitude, newWindow[i + 1].longitude,
      );
    }

    final startPt = newWindow.first;
    final endPt = newWindow.last;
    final straightDist = Geolocator.distanceBetween(
      startPt.latitude, startPt.longitude,
      endPt.latitude, endPt.longitude,
    );
    final durationSeconds =
        endPt.timestamp.difference(startPt.timestamp).inSeconds;
    if (durationSeconds < 1) return;

    final avgSpeed = totalDistance / durationSeconds;
    final consistencyRatio =
        totalDistance > 0 ? straightDist / totalDistance : 0.0;

    StructuredLogger.log(
      LogTag.TRIP,
      'Window=${newWindow.length} pts, Dur=${durationSeconds}s, '
      'Dist=${totalDistance.toStringAsFixed(1)}m, '
      'Speed=${(avgSpeed * 3.6).toStringAsFixed(1)}km/h, '
      'AR=${classification.type.name}(${classification.confidence.toStringAsFixed(2)})',
    );

    bool rulesMet = false;
    BgTripMode estimatedMode = BgTripMode.unknown;

    // GPS speed rules
    if (avgSpeed >= 0.6 && avgSpeed <= 1.8) {
      if (totalDistance >= 30 && durationSeconds >= 30) {
        estimatedMode = BgTripMode.walking;
        rulesMet = true;
      }
    } else if (avgSpeed > 1.8 && avgSpeed <= 5.0) {
      if (totalDistance >= 60 && durationSeconds >= 20) {
        estimatedMode = BgTripMode.walking;
        rulesMet = true;
      }
    } else if (avgSpeed > 5.0) {
      if (totalDistance >= 100 && durationSeconds >= 20) {
        estimatedMode = BgTripMode.vehicle;
        rulesMet = true;
      }
    }

    // Boost confidence if AR agrees (or override if AR is high-confidence)
    if (classification.confidence >= 0.7 &&
        classification.type != NaviQActivityType.stationary &&
        classification.type != NaviQActivityType.unknown) {
      estimatedMode = classification.legacyMode;
      rulesMet = totalDistance >= 20 && durationSeconds >= 20;
    }

    // Direction consistency check
    if (rulesMet && consistencyRatio < 0.6) {
      StructuredLogger.log(
        LogTag.TRIP,
        'Rejected – low consistency ($consistencyRatio)',
      );
      rulesMet = false;
    }

    if (rulesMet) {
      StructuredLogger.log(
        LogTag.TRIP,
        'TRIP CONFIRMED! Mode: $estimatedMode',
      );
      await _startTripTracking(estimatedMode, childId);
    } else {
      _candidatePoints = newWindow;
      _state = BgTripState.candidate;
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // TRIP TRACKING
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> _startTripTracking(BgTripMode mode, String childId) async {
    _isTripTracking = true;
    _tripMode = mode;
    _state = BgTripState.tracking;
    _stopDetector.reset();
    _classifier.reset();

    final pointsToPost = List<Position>.from(_candidatePoints);
    _candidatePoints = [];

    StructuredLogger.log(LogTag.STATE, 'Trip STARTED (mode: $mode)');

    if (pointsToPost.isNotEmpty) {
      await _postTripBatch(pointsToPost, childId);
    }
  }

  void _stopTripTracking() {
    _isTripTracking = false;
    _tripMode = BgTripMode.unknown;
    _state = BgTripState.idle;
    _candidatePoints = [];
    _stopDetector.reset();
    _classifier.reset();
    StructuredLogger.log(LogTag.STATE, 'Trip STOPPED – state reset');
  }

  Future<void> _updateTripLocation(Position pos, String childId) async {
    await _postTripBatch([pos], childId);
  }

  Future<void> _postTripBatch(List<Position> positions, String childId) async {
    if (positions.isEmpty) return;

    int batteryLevel = 0;
    try {
      final infoService = ChildInfoService();
      batteryLevel = await infoService.getBatteryPercentage();
    } catch (_) {
      try {
        batteryLevel = await _battery.batteryLevel;
      } catch (_) {}
    }

    final enhancedPoints = positions
        .map((p) => EnhancedTripPoint.fromPosition(p, battery: batteryLevel))
        .toList();

    final requestBody = {
      'points': enhancedPoints.map((p) => p.toJson()).toList(),
    };

    StructuredLogger.log(
      LogTag.TRIP,
      'Posting ${positions.length} trip points (enhanced)',
    );

    try {
      final response = await _childRepo.postTripLocation(
        childId: childId,
        data: requestBody,
      );

      StructuredLogger.log(
        LogTag.TRIP,
        'Trip post response: ${response.data}',
      );

      if (response.isSuccess && response.data != null) {
        if (_shouldStopTrip(response.data)) {
          StructuredLogger.log(LogTag.TRIP, 'Backend → STOP signal');
          _stopTripTracking();
        }
      } else {
        // Connectivity failure — queue for retry
        await _offlineQueue.enqueuePoints(
          childId: childId,
          points: enhancedPoints,
        );
      }
    } catch (e) {
      StructuredLogger.log(LogTag.TRIP, 'Trip post failed – queuing', error: e);
      await _offlineQueue.enqueuePoints(
        childId: childId,
        points: enhancedPoints,
      );
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // LOCAL STOP DETECTION HANDLER
  // ══════════════════════════════════════════════════════════════════════════

  void _onLocalStopDetected(StopEvent event) {
    if (!_isTripTracking) return;
    StructuredLogger.log(
      LogTag.TRIP,
      '[LocalStop] Stop detected: ${event.duration.inSeconds}s, '
      'r=${event.radiusMeters.toStringAsFixed(1)}m → ending trip locally',
    );
    final childId = _prefs.getString('child_id');
    if (childId != null && childId.isNotEmpty) {
      _postTripEnd(childId, event.detectedAt);
    }
    _stopTripTracking();
  }

  Future<void> _postTripEnd(String childId, DateTime endedAt) async {
    final payload = {'ended_at': endedAt.toIso8601String()};
    try {
      final response = await _childRepo.postTripEnd(childId: childId, data: payload);
      if (!response.isSuccess) {
        await _offlineQueue.enqueueTripEnd(childId: childId, endedAt: endedAt);
      }
    } catch (_) {
      await _offlineQueue.enqueueTripEnd(childId: childId, endedAt: endedAt);
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // OFFLINE QUEUE DRAIN
  // ══════════════════════════════════════════════════════════════════════════

  void _tryDrainOfflineQueue(String childId) {
    if (!_offlineQueue.hasPending) return;

    final now = DateTime.now();
    if (_lastDrainAttempt != null &&
        now.difference(_lastDrainAttempt!).inSeconds < 30) {
      return; // Cooldown limit — try every 30 seconds
    }

    _lastDrainAttempt = now;

    _offlineQueue.drain((entry) async {
      try {
        switch (entry.type) {
          case OfflineEntryType.location:
            final response = await _childRepo.postChildLocation(entry.payload);
            return response.isSuccess;
          case OfflineEntryType.tripPoints:
            final response = await _childRepo.postTripLocation(
              childId: entry.childId,
              data: entry.payload,
            );
            return response.isSuccess;
          case OfflineEntryType.tripEnd:
            final response = await _childRepo.postTripEnd(
              childId: entry.childId,
              data: entry.payload,
            );
            return response.isSuccess;
        }
      } catch (_) {
        return false;
      }
    });
  }

  // ══════════════════════════════════════════════════════════════════════════
  // BACKEND STOP SIGNAL PARSER
  // ══════════════════════════════════════════════════════════════════════════

  bool _shouldStopTrip(dynamic responseData) {
    if (responseData == null) return false;
    try {
      final currentState = responseData['currentState'];
      if (currentState != 'IDLE') return false;
      final transitions = responseData['stateTransitions'];
      if (transitions is List && transitions.isNotEmpty) {
        for (final t in transitions) {
          if (t['to'] == 'ENDED' && t['reason'] == 'STATIONARY_CONFIRMED') {
            return true;
          }
        }
      }
    } catch (e) {
      StructuredLogger.log(LogTag.TRIP, 'Error parsing stop signal', error: e);
    }
    return false;
  }

  // ── Getters ───────────────────────────────────────────────────────────────
  bool get isTripTracking => _isTripTracking;
  BgTripMode get tripMode => _tripMode;
  BgTripState get currentState => _state;
  LocalGeofenceEngine get geofenceEngine => _geoEngine;
}
