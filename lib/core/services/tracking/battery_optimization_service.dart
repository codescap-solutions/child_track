import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:child_track/core/utils/structured_logger.dart';

class BatteryOptimizationService {
  static final BatteryOptimizationService _instance =
      BatteryOptimizationService._internal();
  factory BatteryOptimizationService() => _instance;
  BatteryOptimizationService._internal();

  /// Check if the app is currently being optimized by the OS battery saver.
  /// Returns true if optimization is enabled (i.e. NOT whitelisted).
  /// Returns false if it is whitelisted or on non-Android platforms.
  Future<bool> isOptimizingBattery() async {
    if (!Platform.isAndroid) return false;
    try {
      final isIgnored = await Permission.ignoreBatteryOptimizations.isGranted;
      StructuredLogger.log(
        LogTag.BG,
        '[BatteryOpt] Current status: ${isIgnored ? "whitelisted" : "optimized/restricted"}',
      );
      return !isIgnored;
    } catch (e) {
      StructuredLogger.log(
        LogTag.BG,
        '[BatteryOpt] Failed to check battery optimization status',
        error: e,
      );
      return true; // Assume optimized/restricted by default for safety
    }
  }

  /// Request the user to exclude this app from battery optimizations.
  /// This prompts the native Android system dialog directly.
  Future<bool> requestIgnoreBatteryOptimizations() async {
    if (!Platform.isAndroid) return true;
    try {
      final status = await Permission.ignoreBatteryOptimizations.request();
      final isGranted = status.isGranted;
      StructuredLogger.log(
        LogTag.BG,
        '[BatteryOpt] Ignore battery optimization request status: $status',
      );
      return isGranted;
    } catch (e) {
      StructuredLogger.log(
        LogTag.BG,
        '[BatteryOpt] Failed to request ignore battery optimizations',
        error: e,
      );
      return false;
    }
  }

  /// Redirect the user directly to the app settings page if needed.
  Future<void> openAppSettingsPage() async {
    try {
      await openAppSettings();
    } catch (e) {
      StructuredLogger.log(
        LogTag.BG,
        '[BatteryOpt] Failed to open app settings',
        error: e,
      );
    }
  }

  /// Helper to show user education dialog before requesting.
  Future<void> showBatteryEducationDialog(BuildContext context, {required VoidCallback onConfirm}) async {
    if (!Platform.isAndroid) return;
    
    final isOptimized = await isOptimizingBattery();
    if (!isOptimized) return; // Already whitelisted

    if (!context.mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text('Background Tracking Protection'),
          content: const Text(
            'To ensure your child\'s location is tracked reliably, NaviQ requires permission to run in the background without battery restrictions.\n\n'
            'In the next step, please select "Allow" to exclude NaviQ from Android\'s battery optimizations.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
              },
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                onConfirm();
              },
              child: const Text('PROCEED'),
            ),
          ],
        );
      },
    );
  }
}
