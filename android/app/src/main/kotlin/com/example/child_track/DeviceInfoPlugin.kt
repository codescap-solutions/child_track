package com.truenyx.naviq

import android.app.AppOpsManager
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.media.AudioManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.Process
import android.provider.Settings
import android.util.Log
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.util.Calendar
import java.util.concurrent.Executors

/**
 * FlutterPlugin for device info operations (screen time, installed apps, etc.)
 *
 * Unlike a MethodChannel in MainActivity, a FlutterPlugin auto-registers with
 * EVERY Flutter engine — including WorkManager and FCM background isolates.
 * This ensures getScreenTime() works even when the app is killed.
 */
class DeviceInfoPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {

    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    private var activityBinding: ActivityPluginBinding? = null
    private val executor = Executors.newSingleThreadExecutor()
    private val mainHandler = Handler(Looper.getMainLooper())

    companion object {
        private const val CHANNEL_NAME = "com.truenyx.naviq/device_info"
    }

    // ─── FlutterPlugin Lifecycle ───

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, CHANNEL_NAME)
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    // ─── ActivityAware Lifecycle ───

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activityBinding = binding
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activityBinding = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activityBinding = binding
    }

    override fun onDetachedFromActivity() {
        activityBinding = null
    }

    // ─── MethodCallHandler ───

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {

            "getSoundProfile" -> {
                result.success(getSoundProfile())
            }

            "getInstalledApps" -> {
                executor.execute {
                    try {
                        val includeSystemApps =
                            call.argument<Boolean>("includeSystemApps") ?: true
                        val apps = getInstalledApps(includeSystemApps)
                        mainHandler.post { result.success(apps) }
                    } catch (e: Exception) {
                        mainHandler.post { result.error("ERROR", e.message, null) }
                    }
                }
            }

            "getScreenTime" -> {
                executor.execute {
                    try {
                        val screenTime = getScreenTime()
                        mainHandler.post { result.success(screenTime) }
                    } catch (e: Exception) {
                        mainHandler.post {
                            result.error(
                                "ERROR",
                                "Failed to get screen time: ${e.message}",
                                null
                            )
                        }
                    }
                }
            }

            "checkUsagePermission" -> {
                result.success(hasUsageStatsPermission())
            }

            "openUsageSettings" -> {
                try {
                    val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
                    intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    context.startActivity(intent)
                    result.success(true)
                } catch (e: Exception) {
                    result.error("ERROR", e.message, null)
                }
            }

            else -> result.notImplemented()
        }
    }

    // ─── Sound Profile ───

    private fun getSoundProfile(): String {
        val audioManager =
            context.getSystemService(Context.AUDIO_SERVICE) as AudioManager

        return when (audioManager.ringerMode) {
            AudioManager.RINGER_MODE_NORMAL -> "sound"
            AudioManager.RINGER_MODE_VIBRATE -> "vibrate"
            AudioManager.RINGER_MODE_SILENT -> "silent"
            else -> "unknown"
        }
    }

    // ─── Installed Apps ───

    private fun getInstalledApps(includeSystemApps: Boolean): List<Map<String, Any?>> {

        val apps = mutableListOf<Map<String, Any?>>()
        val pm = context.packageManager

        try {
            val packages = pm.getInstalledPackages(0)

            for (packageInfo in packages) {

                val appInfo = packageInfo.applicationInfo ?: continue
                val packageName = packageInfo.packageName ?: continue

                val isSystemApp =
                    (appInfo.flags and ApplicationInfo.FLAG_SYSTEM) != 0

                if (!includeSystemApps && isSystemApp) continue

                // Skip apps without launch intent
                if (pm.getLaunchIntentForPackage(packageName) == null) {
                    continue
                }

                val appName = try {
                    pm.getApplicationLabel(appInfo).toString()
                } catch (e: Exception) {
                    packageName
                }

                val versionName = packageInfo.versionName

                val versionCode = try {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                        packageInfo.longVersionCode.toInt()
                    } else {
                        @Suppress("DEPRECATION")
                        packageInfo.versionCode
                    }
                } catch (e: Exception) {
                    null
                }

                apps.add(
                    mapOf(
                        "packageName" to packageName,
                        "appName" to appName,
                        "isSystemApp" to isSystemApp,
                        "versionName" to versionName,
                        "versionCode" to versionCode
                    )
                )
            }

        } catch (e: Exception) {
            Log.e("DeviceInfoPlugin", "getInstalledApps error: ${e.message}")
        }

        return apps.sortedBy { (it["appName"] as? String) ?: "" }
    }

    // ─── Screen Time ───

    private fun getScreenTime(): List<Map<String, Any?>> {

        if (!hasUsageStatsPermission()) return emptyList()

        return try {

            val usageStatsManager =
                context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager

            val calendar = Calendar.getInstance()
            calendar.set(Calendar.HOUR_OF_DAY, 0)
            calendar.set(Calendar.MINUTE, 0)
            calendar.set(Calendar.SECOND, 0)
            calendar.set(Calendar.MILLISECOND, 0)

            val startTime = calendar.timeInMillis
            val endTime = System.currentTimeMillis()

            // Use INTERVAL_DAILY instead of queryAndAggregateUsageStats.
            // queryAndAggregateUsageStats sums across overlapping interval buckets
            // which causes totalTimeInForeground to be ~2x the real value.
            // INTERVAL_DAILY returns a single clean per-day stat matching Digital Wellbeing.
            val statsList =
                usageStatsManager.queryUsageStats(UsageStatsManager.INTERVAL_DAILY, startTime, endTime)

            // Manually aggregate by package name (INTERVAL_DAILY may return
            // multiple entries for the same package if query spans midnight)
            val aggregated = mutableMapOf<String, Long>()
            val lastUsedMap = mutableMapOf<String, Long>()

            for (stat in statsList) {
                val pkg = stat.packageName
                val time = stat.totalTimeInForeground
                if (time > 0L) {
                    aggregated[pkg] = (aggregated[pkg] ?: 0L) + time
                    val prev = lastUsedMap[pkg] ?: 0L
                    if (stat.lastTimeUsed > prev) {
                        lastUsedMap[pkg] = stat.lastTimeUsed
                    }
                }
            }

            val pm = context.packageManager

            aggregated.entries
                .mapNotNull { (packageName, totalTime) ->

                    try {
                        pm.getLaunchIntentForPackage(packageName)
                            ?: return@mapNotNull null

                        val appInfo =
                            pm.getApplicationInfo(packageName, 0)

                        val appName = try {
                            pm.getApplicationLabel(appInfo).toString()
                        } catch (e: Exception) {
                            packageName
                        }

                        mapOf(
                            "package" to packageName,
                            "appName" to appName,
                            "seconds" to (totalTime / 1000).toInt(),
                            "lastTimeUsed" to (lastUsedMap[packageName] ?: 0L)
                        )

                    } catch (e: Exception) {
                        null
                    }
                }
                .sortedByDescending { (it["seconds"] as? Int) ?: 0 }

        } catch (e: Exception) {
            Log.e("DeviceInfoPlugin", "getScreenTime error: ${e.message}")
            emptyList()
        }
    }

    // ─── Permission Check ───

    private fun hasUsageStatsPermission(): Boolean {

        val appOps =
            context.getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager

        val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            appOps.unsafeCheckOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                Process.myUid(),
                context.packageName
            )
        } else {
            @Suppress("DEPRECATION")
            appOps.checkOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                Process.myUid(),
                context.packageName
            )
        }

        return mode == AppOpsManager.MODE_ALLOWED
    }
}
