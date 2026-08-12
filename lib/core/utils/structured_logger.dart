import 'package:child_track/core/utils/app_logger.dart';
import 'package:child_track/core/services/csv_file_logger.dart';

enum LogTag {
  STATE,
  LOCATION,
  TRIP,
  BG,
  PERF,
  API,
  CONN,
  PERM,
  GPS,
  LIFECYCLE,
  FCM,
}

class StructuredLogger {
  /// [buffered] batches high-frequency writes (API calls, location fixes)
  /// in memory and flushes periodically instead of hitting disk per call.
  /// Leave false (default) for low-frequency/crash-relevant events, where
  /// an immediate flushed write matters more than write-batching.
  static void log(
    LogTag tag,
    String message, {
    dynamic error,
    bool buffered = false,
  }) {
    final tagString = tag.toString().split('.').last;
    final formattedMessage = '[$tagString] $message';

    if (error != null) {
      AppLogger.error(formattedMessage, error);
      // Also write to CSV file for offline analysis
      CsvFileLogger.instance.write(
        tag: tagString,
        level: 'ERROR',
        message: '$message | error: $error',
      );
    } else {
      AppLogger.info(formattedMessage);
      CsvFileLogger.instance.write(
        tag: tagString,
        level: 'INFO',
        message: message,
        buffered: buffered,
      );
    }
  }
}
