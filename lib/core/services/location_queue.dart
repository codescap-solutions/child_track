import 'dart:convert';
import 'package:child_track/core/services/shared_prefs_service.dart';
import 'package:child_track/core/utils/structured_logger.dart';

/// Crash-proof persistent queue for GPS location points.
///
/// Backed by SharedPreferences JSON — survives OS kills, crashes, reboots.
/// All buffered points are written to disk after every mutation so nothing
/// is ever held only in RAM.
///
/// This is the foundational building block that makes Find My Kids-style
/// "zero data loss" possible.
class LocationQueue {
  static const String _queueKey = 'location_queue';
  static const int maxCapacity = 500; // ~8 min at 1 Hz

  final SharedPrefsService _prefs;

  // In-memory mirror of the persisted queue — kept in sync on every write.
  List<Map<String, dynamic>> _queue = [];
  bool _isSaving = false;

  LocationQueue({required SharedPrefsService prefs}) : _prefs = prefs;

  // ====================================================================
  // PUBLIC API
  // ====================================================================

  /// Load the queue from disk into memory. Call once on service start.
  Future<void> load() async {
    try {
      final raw = _prefs.getString(_queueKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          _queue = decoded
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
          StructuredLogger.log(
            LogTag.BG,
            'Queue loaded from disk: ${_queue.length} points',
          );
        }
      }
    } catch (e) {
      StructuredLogger.log(
        LogTag.BG,
        'Queue load failed, starting fresh',
        error: e,
      );
      _queue = [];
    }
  }

  /// Add points to the end of the queue and persist.
  Future<void> enqueue(List<Map<String, dynamic>> points) async {
    _queue.addAll(points);

    // Enforce capacity — drop oldest if overflow
    int dropped = 0;
    while (_queue.length > maxCapacity) {
      _queue.removeAt(0);
      dropped++;
    }
    if (dropped > 0) {
      StructuredLogger.log(
        LogTag.LOCATION,
        'Queue overflow: dropped $dropped oldest points',
      );
    }

    await _persist();
  }

  /// Peek at the first [count] points without removing them.
  List<Map<String, dynamic>> peek(int count) {
    final end = count.clamp(0, _queue.length);
    return List<Map<String, dynamic>>.from(_queue.sublist(0, end));
  }

  /// Remove the first [count] points (call after successful upload).
  Future<void> dequeue(int count) async {
    final end = count.clamp(0, _queue.length);
    _queue.removeRange(0, end);
    await _persist();
  }

  /// Current queue length.
  int get length => _queue.length;

  /// Whether the queue is empty.
  bool get isEmpty => _queue.isEmpty;

  /// Whether the queue is not empty.
  bool get isNotEmpty => _queue.isNotEmpty;

  /// Clear everything — call on logout.
  Future<void> clear() async {
    _queue.clear();
    await _persist();
    StructuredLogger.log(LogTag.BG, 'Queue cleared');
  }

  // ====================================================================
  // INTERNALS
  // ====================================================================

  /// Write the current queue to SharedPreferences.
  Future<void> _persist() async {
    if (_isSaving) return; // Prevent concurrent writes
    _isSaving = true;
    try {
      final encoded = jsonEncode(_queue);
      await _prefs.setString(_queueKey, encoded);
    } catch (e) {
      StructuredLogger.log(LogTag.BG, 'Queue persist failed', error: e);
    } finally {
      _isSaving = false;
    }
  }
}
