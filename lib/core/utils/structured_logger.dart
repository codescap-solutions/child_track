import 'package:child_track/core/utils/app_logger.dart';
import 'package:child_track/core/services/csv_file_logger.dart';

enum LogTag { STATE, LOCATION, TRIP, BG, PERF }

class StructuredLogger {
  static void log(LogTag tag, String message, {dynamic error}) {
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
      );
    }
  }
}
