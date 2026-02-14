import 'package:child_track/core/utils/app_logger.dart';

enum LogTag { STATE, LOCATION, TRIP, BG, PERF }

class StructuredLogger {
  static void log(LogTag tag, String message, {dynamic error}) {
    final tagString = tag.toString().split('.').last;
    final formattedMessage = '[$tagString] $message';

    if (error != null) {
      AppLogger.error(formattedMessage, error);
    } else {
      AppLogger.info(formattedMessage);
    }
  }
}
