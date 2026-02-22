import 'dart:async';

/// Severity level for debug log entries.
enum LogLevel { info, success, warning, error }

/// A single log entry with timestamp, level, tag, and message.
class DebugLogEntry {
  final DateTime time;
  final LogLevel level;
  final String tag;
  final String message;

  DebugLogEntry({required this.level, required this.tag, required this.message})
    : time = DateTime.now();

  String get timeFormatted {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    final s = time.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  String get emoji {
    switch (level) {
      case LogLevel.info:
        return 'ℹ️';
      case LogLevel.success:
        return '✅';
      case LogLevel.warning:
        return '⚠️';
      case LogLevel.error:
        return '❌';
    }
  }
}

/// In-memory debug log sink. Singleton — accessible from anywhere.
///
/// The foreground service isolate cannot share memory with the main isolate,
/// so this service captures logs from the main isolate side (API responses,
/// UI events). For foreground service logs, we relay via service.invoke().
class DebugLogService {
  static final DebugLogService _instance = DebugLogService._internal();
  factory DebugLogService() => _instance;
  DebugLogService._internal();

  static const int _maxEntries = 200;
  final List<DebugLogEntry> _entries = [];

  /// Stream controller for real-time UI updates.
  final _controller = StreamController<List<DebugLogEntry>>.broadcast();
  Stream<List<DebugLogEntry>> get stream => _controller.stream;

  /// Current snapshot of all entries.
  List<DebugLogEntry> get entries => List.unmodifiable(_entries);

  /// Add a log entry.
  void log(LogLevel level, String tag, String message) {
    final entry = DebugLogEntry(level: level, tag: tag, message: message);
    _entries.add(entry);

    // Cap size
    while (_entries.length > _maxEntries) {
      _entries.removeAt(0);
    }

    // Notify listeners
    if (!_controller.isClosed) {
      _controller.add(List.unmodifiable(_entries));
    }
  }

  // ── Convenience methods ────────────────────────────────────────────

  void info(String tag, String message) => log(LogLevel.info, tag, message);
  void success(String tag, String message) =>
      log(LogLevel.success, tag, message);
  void warning(String tag, String message) =>
      log(LogLevel.warning, tag, message);
  void error(String tag, String message) => log(LogLevel.error, tag, message);

  // ── Tracking-specific helpers ──────────────────────────────────────

  void batchQueued(int count, int queueTotal) =>
      info('QUEUE', '+$count points queued (total: $queueTotal)');

  void batchUploading(int count, String batchId) =>
      info('UPLOAD', 'Sending $count points [${batchId.substring(0, 8)}...]');

  void batchSuccess(int count, int remaining) =>
      success('UPLOAD', '$count points uploaded ✓ ($remaining remaining)');

  void batchFailed(String reason) => error('UPLOAD', 'Batch failed: $reason');

  void batchDropped(String reason) =>
      warning('UPLOAD', 'Batch DROPPED (non-retryable): $reason');

  void backoffChanged(int seconds, int failures) =>
      warning('RETRY', 'Backoff: ${seconds}s (failures: $failures)');

  void tripEvent(String status, String? tripId) =>
      success('TRIP', 'Trip $status${tripId != null ? " [$tripId]" : ""}');

  void serviceEvent(String message) => info('SERVICE', message);

  void apiResponse(String endpoint, int? statusCode, String? message) {
    if (statusCode != null && statusCode >= 200 && statusCode < 300) {
      success('API', '$endpoint → $statusCode');
    } else {
      error('API', '$endpoint → ${statusCode ?? "?"}: ${message ?? "unknown"}');
    }
  }

  /// Clear all logs.
  void clear() {
    _entries.clear();
    if (!_controller.isClosed) {
      _controller.add([]);
    }
  }

  void dispose() {
    _controller.close();
  }
}
