import 'package:workmanager/workmanager.dart';
import 'package:child_track/core/services/shared_prefs_service.dart';
import 'package:child_track/app/childapp/view_model/repository/device_info_service.dart';
import 'package:child_track/app/childapp/view_model/repository/child_repo.dart';
import 'package:child_track/core/services/screen_time_sync_service.dart';
import 'package:child_track/core/services/dio_client.dart';
import 'package:child_track/core/utils/app_logger.dart';

const String screenTimeSyncTask = "screen_time_sync";
const String onDemandSyncTask =
    "on_demand_sync"; // Unique name for one-off task

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    AppLogger.info("Background Task Started: $task");

    try {
      // 1. Initialize SharedPreferences
      await SharedPrefsService.init();
      final prefs = SharedPrefsService();

      // 2. Initialize Services manually (DI not available)
      final deviceInfo = ChildInfoService();

      // 3. Initialize Repo with manual DioClient (no DI/Blocs)
      // Pass the initialized prefs to DioClient to avoid it trying to use injector
      final dioClient = DioClient(sharedPrefsService: prefs);
      final repo = ChildRepo(dioClient: dioClient, sharedPrefsService: prefs);

      // 4. Run Sync Service
      final syncService = ScreenTimeSyncService(deviceInfo, repo, prefs, dioClient);

      switch (task) {
        case screenTimeSyncTask:
          await syncService.syncScreenTime();
          break;
        default:
          AppLogger.warning("Unknown background task: $task");
          break;
      }
    } catch (e, stack) {
      AppLogger.error("Background Task Failed: $e", null, stack);
      return Future.value(false);
    }

    return Future.value(true);
  });
}

class BackgroundTaskService {
  static Future<void> initialize() async {
    await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
  }

  static Future<void> schedulePeriodicSync() async {
    AppLogger.info("Scheduling periodic screen time sync...");
    await Workmanager().registerPeriodicTask(
      "periodic_screen_time_sync",
      screenTimeSyncTask,
      frequency: const Duration(minutes: 30),
      constraints: Constraints(
        networkType: NetworkType.connected,
        requiresBatteryNotLow: true,
      ),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
    );
  }

  static Future<void> triggerImmediateSync() async {
    AppLogger.info("Triggering immediate screen time sync...");
    await Workmanager().registerOneOffTask(
      onDemandSyncTask,
      screenTimeSyncTask, // Re-use the same task name for the callback dispatcher
      constraints: Constraints(networkType: NetworkType.connected),
      existingWorkPolicy: ExistingWorkPolicy.replace,
    );
  }

  static Future<void> cancelAll() async {
    await Workmanager().cancelAll();
  }
}
