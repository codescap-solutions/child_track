import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:child_track/core/utils/app_logger.dart';

/// Writes structured log entries to a CSV file on disk so the user can
/// pull the file and analyse background-service behaviour.
///
/// CSV columns: `timestamp,tag,level,message`
///
/// The file is stored at `<app-docs>/logs/bg_log_<YYYY-MM-DD>.csv`
/// (one file per day to avoid unbounded growth).
class CsvFileLogger {
  CsvFileLogger._();
  static final CsvFileLogger instance = CsvFileLogger._();

  static const int _maxBufferedRows = 20;
  static const Duration _flushInterval = Duration(seconds: 2);

  File? _logFile;
  bool _initialised = false;

  final List<String> _buffer = [];
  Timer? _flushTimer;

  /// Must be called once (e.g. from background service onStart).
  Future<void> init() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final logDir = Directory('${dir.path}/logs');
      if (!logDir.existsSync()) {
        logDir.createSync(recursive: true);
      }

      final today = DateTime.now().toIso8601String().substring(0, 10);
      _logFile = File('${logDir.path}/bg_log_$today.csv');

      // Write header if brand-new file
      if (!_logFile!.existsSync()) {
        await _logFile!.writeAsString('timestamp,tag,level,message\n');
      }

      _initialised = true;
      _flushTimer ??= Timer.periodic(_flushInterval, (_) => _flushBuffer());
      AppLogger.info('CsvFileLogger: ready → ${_logFile!.path}');
    } catch (e) {
      AppLogger.error('CsvFileLogger: init failed', e);
    }
  }

  /// Append a row. Fire-and-forget — never blocks the caller.
  ///
  /// [buffered] batches the row in memory and flushes it on the next
  /// periodic tick (or once [_maxBufferedRows] accumulate) instead of
  /// hitting disk immediately — use only for high-frequency, low-severity
  /// events (e.g. API calls, location fixes). ERROR-level rows always
  /// flush immediately regardless of this flag, since those are the rows
  /// most likely to matter right before a crash/kill.
  void write({
    required String tag,
    required String level,
    required String message,
    bool buffered = false,
  }) {
    if (!_initialised || _logFile == null) return;

    try {
      final ts = DateTime.now().toUtc().toIso8601String();
      // Escape any commas / newlines in the message
      final safeMsg = message.replaceAll('"', '""').replaceAll('\n', ' ');
      final row = '$ts,$tag,$level,"$safeMsg"\n';

      if (buffered && level != 'ERROR') {
        _buffer.add(row);
        if (_buffer.length >= _maxBufferedRows) {
          _flushBuffer();
        }
        return;
      }

      // Use sync write inside isolate (background service runs in its own isolate)
      _logFile!.writeAsStringSync(row, mode: FileMode.append, flush: true);
    } catch (_) {
      // Silently ignore write errors – logging must never crash the service
    }
  }

  void _flushBuffer() {
    if (_buffer.isEmpty || _logFile == null) return;
    try {
      final rows = _buffer.join();
      _buffer.clear();
      _logFile!.writeAsStringSync(rows, mode: FileMode.append, flush: true);
    } catch (_) {
      // Silently ignore write errors – logging must never crash the service
    }
  }

  /// Forces any buffered rows to disk now. Call this on app backgrounding
  /// or before reading/sharing/clearing logs, so buffered rows are never
  /// silently lost or missing from an export.
  void flush() => _flushBuffer();

  /// Returns the path to today's log file (for UI display or sharing).
  String? get currentLogPath => _logFile?.path;

  /// Returns paths of all existing log files (for export / share).
  Future<List<String>> getAllLogPaths() async {
    // Ensure any buffered-but-not-yet-flushed rows are on disk before the
    // caller reads, shares, or deletes files — readLogs/clearLogs both
    // route through this method.
    _flushBuffer();
    try {
      final dir = await getApplicationDocumentsDirectory();
      final logDir = Directory('${dir.path}/logs');
      if (!logDir.existsSync()) return [];

      return logDir
          .listSync()
          .where((f) => f.path.endsWith('.csv'))
          .map((f) => f.path)
          .toList()
        ..sort();
    } catch (_) {
      return [];
    }
  }

  /// Reads and parses all logs from today and previous days, returning list of raw log rows.
  Future<List<String>> readLogs() async {
    try {
      final paths = await getAllLogPaths();
      final List<String> logs = [];
      for (final path in paths.reversed) {
        final file = File(path);
        if (file.existsSync()) {
          final lines = await file.readAsLines();
          if (lines.length > 1) {
            // Skip CSV header line and add in reverse order (newest first)
            logs.addAll(lines.skip(1).toList().reversed);
          }
        }
      }
      return logs;
    } catch (_) {
      return [];
    }
  }

  /// Deletes all CSV log files on disk and reinitializes the log directory/today's file.
  Future<void> clearLogs() async {
    try {
      final paths = await getAllLogPaths();
      for (final path in paths) {
        final file = File(path);
        if (file.existsSync()) {
          await file.delete();
        }
      }
      _initialised = false;
      await init();
    } catch (_) {}
  }
}
