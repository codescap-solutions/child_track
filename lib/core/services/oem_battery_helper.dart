import 'dart:io';
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:child_track/core/services/shared_prefs_service.dart';
import 'package:child_track/core/utils/app_logger.dart';

/// Standard Android battery-optimization exemption (ignoreBatteryOptimizations,
/// prompted in permission_sequence_screen.dart) only covers stock Android's
/// Doze/App Standby. Several OEMs run their own, stricter background-kill
/// managers on top of that — a device can be fully exempted from stock
/// Doze and still get its background service killed by e.g. MIUI's
/// Autostart manager. This was confirmed as the likely cause of a real
/// 27-minute location gap on a ColorOS (Oppo) test device earlier this
/// project. This helper detects those OEMs and offers manufacturer-specific
/// whitelisting guidance on top of the standard prompt.
class OemBatteryHelper {
  static const _acknowledgedPrefKey = 'oem_battery_step_acknowledged';

  // MIUI (Xiaomi's Android skin) is shared across three distinct
  // Build.MANUFACTURER strings — "Xiaomi", "Redmi", and "POCO" all report
  // separately despite running the identical underlying battery/autostart
  // manager, since Xiaomi spun both off as their own sub-brands. Confirmed
  // directly relevant: a real delayed-notification incident (a ~140min
  // geofence-report delay, traced to a device-side offline queue) was on a
  // POCO device — which this map didn't recognize at all before this fix,
  // so it would have gotten no OEM guidance despite needing the exact same
  // MIUI Autostart whitelist as Xiaomi/Redmi.
  static const _miuiOem = OemInfo(
    displayName: 'Xiaomi (MIUI)',
    settingLabel: 'Autostart',
    intentPackage: 'com.miui.securitycenter',
    intentComponent: 'com.miui.permcenter.autostart.AutoStartManagementActivity',
    manualSteps: [
      'Open Security app (or Settings)',
      'Go to "Permissions" → "Autostart"',
      'Find NaviQ and turn it ON',
      'Also check Settings → Apps → Manage apps → NaviQ → Battery saver → set to "No restrictions"',
    ],
  );

  /// Manufacturer strings as reported by Build.MANUFACTURER (lowercase).
  /// Deep-link intents below target the actual settings activity each OEM
  /// ships for this purpose — these are unofficial (not part of the public
  /// Android SDK) and can stop working across OEM software updates, which
  /// is exactly why every one of them has a manual-navigation fallback.
  static const Map<String, OemInfo> _knownOems = {
    'xiaomi': _miuiOem,
    'redmi': _miuiOem,
    'poco': _miuiOem,
    'oppo': OemInfo(
      displayName: 'Oppo (ColorOS)',
      settingLabel: 'Allow background activity',
      intentPackage: 'com.coloros.safecenter',
      intentComponent:
          'com.coloros.safecenter.permission.startup.StartupAppListActivity',
      manualSteps: [
        'Settings → Battery → App Battery Management → NaviQ → "Allow background activity" (or "No restrictions")',
        'Settings → App Management → App List → NaviQ → App startup → Manage manually → enable Auto-launch, Secondary launch, and Run in background',
        'In Recent Apps, swipe up on NaviQ and tap the lock icon so it isn\'t cleared from memory',
      ],
    ),
    'realme': OemInfo(
      displayName: 'Realme (Realme UI)',
      settingLabel: 'Allow background activity',
      intentPackage: 'com.coloros.safecenter',
      intentComponent:
          'com.coloros.safecenter.permission.startup.StartupAppListActivity',
      manualSteps: [
        'Settings → Battery → App Battery Management → NaviQ → "Allow background activity"',
        'Settings → App Management → App List → NaviQ → App startup → Manage manually → enable all toggles',
        'In Recent Apps, swipe up on NaviQ and tap the lock icon',
      ],
    ),
    'vivo': OemInfo(
      displayName: 'Vivo (Funtouch/OriginOS)',
      settingLabel: 'High background power consumption',
      intentPackage: 'com.vivo.permissionmanager',
      intentComponent:
          'com.vivo.permissionmanager.activity.BgStartUpManagerActivity',
      manualSteps: [
        'Settings → Battery → Background power consumption management → find NaviQ and allow it',
        'i Manager → App manager → Autostart manager → enable NaviQ',
        'In Recent Apps, swipe down on NaviQ\'s card and lock it',
      ],
    ),
    'oneplus': OemInfo(
      displayName: 'OnePlus (OxygenOS)',
      settingLabel: 'Battery optimization',
      intentPackage: 'com.oneplus.security',
      intentComponent:
          'com.oneplus.security.chainlaunch.view.ChainLaunchAppListActivity',
      manualSteps: [
        'Settings → Battery → Battery optimization → NaviQ → set to "Don\'t optimize"',
        'Settings → Apps → Special app access → look for "Advanced optimization" and exclude NaviQ',
        'In Recent Apps, swipe down on NaviQ\'s card and lock it',
      ],
    ),
  };

  final SharedPrefsService _prefs;
  OemBatteryHelper({SharedPrefsService? prefs}) : _prefs = prefs ?? SharedPrefsService();

  /// Returns the matched OEM info for this device, or null if it's stock
  /// Android / an unrecognized manufacturer (nothing extra needed beyond
  /// the standard ignoreBatteryOptimizations prompt).
  Future<OemInfo?> detectOem() async {
    if (!Platform.isAndroid) return null;
    try {
      final info = await DeviceInfoPlugin().androidInfo;
      final manufacturer = info.manufacturer.toLowerCase().trim();
      return _knownOems[manufacturer];
    } catch (e) {
      AppLogger.error('OemBatteryHelper: manufacturer detection failed: $e');
      return null;
    }
  }

  /// Attempts to open the OEM's dedicated settings screen directly.
  /// Returns false if the intent couldn't be resolved/launched (e.g. the
  /// OEM changed the activity name in a software update) — caller should
  /// show the manual-steps fallback in that case.
  Future<bool> openOemSettings(OemInfo oem) async {
    try {
      final intent = AndroidIntent(
        action: 'android.intent.action.MAIN',
        package: oem.intentPackage,
        componentName: oem.intentComponent,
        flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
      );
      await intent.launch();
      return true;
    } catch (e) {
      AppLogger.warning('OemBatteryHelper: deep link failed for ${oem.displayName}: $e');
      return false;
    }
  }

  Future<void> markAcknowledged() async {
    await _prefs.setBool(_acknowledgedPrefKey, true);
  }

  bool get isAcknowledged => _prefs.getBool(_acknowledgedPrefKey);
}

class OemInfo {
  final String displayName;
  final String settingLabel;
  final String intentPackage;
  final String intentComponent;
  final List<String> manualSteps;

  const OemInfo({
    required this.displayName,
    required this.settingLabel,
    required this.intentPackage,
    required this.intentComponent,
    required this.manualSteps,
  });
}
