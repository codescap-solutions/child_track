import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:child_track/core/services/csv_file_logger.dart';
import 'package:child_track/core/utils/app_logger.dart';

/// Shares every stored diagnostic log CSV file via the OS share sheet.
/// Shared by both the child-device drawer's "Share Logs" action and the
/// Diagnostic Logs viewer sheet, so the behavior stays identical everywhere.
Future<void> shareCsvLogFiles(BuildContext context) async {
  try {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Preparing logs…')));

    final paths = await CsvFileLogger.instance.getAllLogPaths();
    if (!context.mounted) return;
    if (paths.isEmpty) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No log files found yet')));
      return;
    }

    final xFiles = paths.map((p) => XFile(p)).toList();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    await SharePlus.instance.share(
      ShareParams(files: xFiles, subject: 'NaviQ Background Logs'),
    );
  } catch (e) {
    AppLogger.error('Share logs error: $e');
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Failed to share logs: $e')));
  }
}
