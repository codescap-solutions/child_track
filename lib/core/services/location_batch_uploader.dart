import 'dart:async';
import 'package:battery_plus/battery_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';
import 'package:child_track/app/childapp/view_model/repository/child_repo.dart';
import 'package:child_track/core/services/shared_prefs_service.dart';
import 'package:child_track/core/services/location_queue.dart';
import 'package:child_track/core/services/debug_log_service.dart';
import 'package:child_track/core/utils/structured_logger.dart';

/// Production-grade GPS batch uploader.
///
/// Architecture (matches Find My Kids / Life360):
/// - **Persistent queue**: Points survive OS kill, crash, reboot
/// - **UUID idempotency**: Each batch has a unique ID for server dedup
/// - **Exponential backoff**: 30s → 60s → 120s → 300s on failure
/// - **Error classification**: 4xx = drop (non-retryable), 5xx = retry
/// - **Single system**: No client-side trip detection — backend owns trip logic
class LocationBatchUploader {
  final ChildRepo _childRepo;
  final SharedPrefsService _prefs;
  final LocationQueue _queue;
  final Uuid _uuid = const Uuid();
  final DebugLogService _debug = DebugLogService();

  // ── Timers & Backoff ────────────────────────────────────────────────
  Timer? _flushTimer;
  static const int _baseIntervalSeconds = 30;
  static const int _maxIntervalSeconds = 300; // 5 min cap
  int _currentIntervalSeconds = _baseIntervalSeconds;
  int _consecutiveFailures = 0;

  // ── Batching Config ─────────────────────────────────────────────────
  static const int _batchSize = 30; // max points per HTTP call
  static const double _displacementThresholdMeters = 50.0;
  Position? _lastFlushedPosition;

  // ── Battery ─────────────────────────────────────────────────────────
  final Battery _battery = Battery();
  int _cachedBatteryLevel = -1;
  DateTime? _lastBatteryCheck;
  static const Duration _batteryCheckInterval = Duration(minutes: 2);

  // ── Lifecycle ───────────────────────────────────────────────────────
  bool _isDisposed = false;
  bool _isFlushing = false;

  LocationBatchUploader({
    required ChildRepo childRepo,
    required SharedPrefsService prefs,
    required LocationQueue queue,
  }) : _childRepo = childRepo,
       _prefs = prefs,
       _queue = queue;

  // ====================================================================
  // PUBLIC API
  // ====================================================================

  /// Initialize and start. Loads persisted queue and flushes stale points.
  Future<void> start() async {
    _isDisposed = false;

    // Load any points that survived a previous kill/crash
    await _queue.load();
    if (_queue.isNotEmpty) {
      StructuredLogger.log(
        LogTag.BG,
        'Recovered ${_queue.length} persisted points from last session',
      );
      _debug.serviceEvent(
        'Recovered ${_queue.length} points from last session',
      );
    }

    _resetBackoff();
    _scheduleNextFlush();
    StructuredLogger.log(LogTag.BG, 'BatchUploader started');
    _debug.serviceEvent('BatchUploader started');
  }

  /// Feed every GPS position from the location stream.
  Future<void> addPoint(Position position) async {
    if (_isDisposed) return;

    final batteryLevel = await _getBatteryLevel();
    final point = <String, dynamic>{
      'lat': position.latitude,
      'lon': position.longitude,
      'ts': position.timestamp.toUtc().toIso8601String(),
      'accuracy': position.accuracy,
      'speed': position.speed,
      'bearing': position.heading,
      'provider': 'gps',
      'battery': batteryLevel,
    };

    await _queue.enqueue([point]);
    _debug.batchQueued(1, _queue.length);

    StructuredLogger.log(
      LogTag.LOCATION,
      'Queued (${_queue.length} total): '
      '${position.latitude.toStringAsFixed(5)}, '
      '${position.longitude.toStringAsFixed(5)} | '
      'spd ${position.speed.toStringAsFixed(1)} m/s',
    );

    // Displacement-based flush
    if (_lastFlushedPosition != null) {
      final displacement = Geolocator.distanceBetween(
        _lastFlushedPosition!.latitude,
        _lastFlushedPosition!.longitude,
        position.latitude,
        position.longitude,
      );
      if (displacement >= _displacementThresholdMeters) {
        StructuredLogger.log(
          LogTag.LOCATION,
          'Displacement flush (${displacement.toStringAsFixed(0)}m)',
        );
        await _flush();
        return;
      }
    }

    // Safety cap flush
    if (_queue.length >= _batchSize * 2) {
      StructuredLogger.log(LogTag.LOCATION, 'Cap flush triggered');
      await _flush();
    }
  }

  /// Graceful shutdown — flush remaining, persist leftovers.
  Future<void> dispose() async {
    _isDisposed = true;
    _flushTimer?.cancel();
    _flushTimer = null;

    if (_queue.isNotEmpty) {
      StructuredLogger.log(
        LogTag.BG,
        'Final flush on dispose (${_queue.length} points)',
      );
      await _flush();
    }

    // Queue is already persisted — survives even if flush failed
    StructuredLogger.log(
      LogTag.BG,
      'BatchUploader disposed (${_queue.length} points persisted for next session)',
    );
  }

  /// Clear queue — call on logout.
  Future<void> clearQueue() async {
    await _queue.clear();
    _lastFlushedPosition = null;
    _resetBackoff();
    StructuredLogger.log(LogTag.BG, 'Queue cleared on logout');
  }

  // ====================================================================
  // FLUSH ENGINE
  // ====================================================================

  void _scheduleNextFlush() {
    _flushTimer?.cancel();
    if (_isDisposed) return;

    _flushTimer = Timer(Duration(seconds: _currentIntervalSeconds), () async {
      await _flush();
      _scheduleNextFlush(); // Re-schedule after flush completes
    });
  }

  Future<void> _flush() async {
    if (_queue.isEmpty || _isFlushing || _isDisposed) return;

    final childId = _prefs.getString('child_id');
    if (childId == null || childId.isEmpty) {
      StructuredLogger.log(LogTag.BG, 'Flush skipped — no child_id');
      return;
    }

    _isFlushing = true;

    try {
      // Take a batch from the front of the queue
      final batchSize = _batchSize.clamp(1, _queue.length);
      final batch = _queue.peek(batchSize);
      final batchId = _uuid.v4();

      _debug.batchUploading(batch.length, batchId);
      StructuredLogger.log(
        LogTag.TRIP,
        'Flushing ${batch.length} points [batch=$batchId] for child $childId',
      );

      final response = await _childRepo.postBatchLocations(
        childId: childId,
        data: {'batch_id': batchId, 'points': batch},
      );

      if (response.isSuccess) {
        // ── SUCCESS: remove uploaded points ──
        await _queue.dequeue(batchSize);
        _resetBackoff();

        // Update last flushed position for displacement checks
        if (batch.isNotEmpty) {
          final lastPt = batch.last;
          _lastFlushedPosition = Position(
            latitude: (lastPt['lat'] as num).toDouble(),
            longitude: (lastPt['lon'] as num).toDouble(),
            timestamp: DateTime.parse(lastPt['ts'] as String),
            accuracy: (lastPt['accuracy'] as num).toDouble(),
            altitude: 0,
            altitudeAccuracy: 0,
            heading: (lastPt['bearing'] as num).toDouble(),
            headingAccuracy: 0,
            speed: (lastPt['speed'] as num).toDouble(),
            speedAccuracy: 0,
          );
        }

        _debug.batchSuccess(batch.length, _queue.length);
        StructuredLogger.log(
          LogTag.TRIP,
          'Batch success (${batch.length} pts). Queue: ${_queue.length} remaining',
        );

        // If more points remain, flush again immediately
        if (_queue.isNotEmpty && !_isDisposed) {
          await _flush();
        }
      } else {
        // ── FAILURE: classify error ──
        _handleUploadFailure(response.message);
      }
    } catch (e) {
      // Network error, timeout, connectivity exception — all retryable
      StructuredLogger.log(LogTag.TRIP, 'Flush error (retryable)', error: e);
      _debug.batchFailed('$e');
      _incrementBackoff();
    } finally {
      _isFlushing = false;
    }
  }

  // ====================================================================
  // ERROR CLASSIFICATION
  // ====================================================================

  void _handleUploadFailure(String message) {
    final lowerMsg = message.toLowerCase();

    // 400 Bad Request — client error, retrying won't help
    if (lowerMsg.contains('bad request') || lowerMsg.contains('400')) {
      StructuredLogger.log(
        LogTag.TRIP,
        'FATAL: 400 Bad Request — dropping batch. Msg: $message',
      );
      // Drop the batch to prevent infinite retry
      final dropSize = _batchSize.clamp(1, _queue.length);
      _queue.dequeue(dropSize);
      _resetBackoff();
      return;
    }

    // 403 Forbidden — child disabled or unauthorized
    if (lowerMsg.contains('access denied') || lowerMsg.contains('403')) {
      StructuredLogger.log(
        LogTag.TRIP,
        'FATAL: 403 Forbidden — dropping batch. Child may be disabled.',
      );
      final dropSize = _batchSize.clamp(1, _queue.length);
      _queue.dequeue(dropSize);
      _resetBackoff();
      return;
    }

    // 404 Not Found — endpoint misconfigured
    if (lowerMsg.contains('not found') || lowerMsg.contains('404')) {
      StructuredLogger.log(
        LogTag.TRIP,
        'FATAL: 404 Not Found — dropping batch.',
      );
      final dropSize = _batchSize.clamp(1, _queue.length);
      _queue.dequeue(dropSize);
      _resetBackoff();
      return;
    }

    // 401 — DioClient interceptor should have refreshed token already.
    // If we still get here, treat as retryable (next attempt will have new token).
    // 5xx, timeout, connection error — retryable with backoff
    StructuredLogger.log(
      LogTag.TRIP,
      'Retryable failure: $message. Backoff: ${_currentIntervalSeconds}s',
    );
    _incrementBackoff();
  }

  // ====================================================================
  // BACKOFF
  // ====================================================================

  void _resetBackoff() {
    _consecutiveFailures = 0;
    _currentIntervalSeconds = _baseIntervalSeconds;
  }

  void _incrementBackoff() {
    _consecutiveFailures++;
    // Exponential: 30 → 60 → 120 → 240 → 300 (cap)
    _currentIntervalSeconds =
        (_baseIntervalSeconds * (1 << _consecutiveFailures)).clamp(
          _baseIntervalSeconds,
          _maxIntervalSeconds,
        );

    StructuredLogger.log(
      LogTag.TRIP,
      'Backoff incremented: ${_currentIntervalSeconds}s '
      '(failures: $_consecutiveFailures)',
    );
  }

  // ====================================================================
  // BATTERY
  // ====================================================================

  Future<int> _getBatteryLevel() async {
    final now = DateTime.now();
    if (_cachedBatteryLevel < 0 ||
        _lastBatteryCheck == null ||
        now.difference(_lastBatteryCheck!) > _batteryCheckInterval) {
      try {
        _cachedBatteryLevel = await _battery.batteryLevel;
        _lastBatteryCheck = now;
      } catch (_) {
        if (_cachedBatteryLevel < 0) _cachedBatteryLevel = -1;
      }
    }
    return _cachedBatteryLevel;
  }
}
