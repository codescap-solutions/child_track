package com.truenyx.naviq

import android.app.AppOpsManager
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.media.AudioManager
import android.os.Build
import android.os.Process
import android.provider.Settings
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.Calendar
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {

    private val CHANNEL = "com.truenyx.naviq/device_info"

    // Dedicated background executor (better than creating new Thread every time)
    private val executor = Executors.newSingleThreadExecutor()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->

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

                            runOnUiThread {
                                result.success(apps)
                            }
                        } catch (e: Exception) {
                            runOnUiThread {
                                result.error("ERROR", e.message, null)
                            }
                        }
                    }
                }

                "getScreenTime" -> {
                    executor.execute {
                        try {
                            val screenTime = getScreenTime()
                            runOnUiThread {
                                result.success(screenTime)
                            }
                        } catch (e: Exception) {
                            runOnUiThread {
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
                        val intent =
                            Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                }

                else -> result.notImplemented()
            }
        }
    }

    // ----------------------------
    // SOUND PROFILE
    // ----------------------------
    private fun getSoundProfile(): String {
        val audioManager =
            getSystemService(Context.AUDIO_SERVICE) as AudioManager

        return when (audioManager.ringerMode) {
            AudioManager.RINGER_MODE_NORMAL -> "sound"
            AudioManager.RINGER_MODE_VIBRATE -> "vibrate"
            AudioManager.RINGER_MODE_SILENT -> "silent"
            else -> "unknown"
        }
    }

    // ----------------------------
    // INSTALLED APPS (OPTIMIZED)
    // ----------------------------
    private fun getInstalledApps(includeSystemApps: Boolean): List<Map<String, Any?>> {

        val apps = mutableListOf<Map<String, Any?>>()
        val packageManager = packageManager

        try {
            val packages =
                packageManager.getInstalledPackages(0)

            for (packageInfo in packages) {

                val appInfo = packageInfo.applicationInfo ?: continue
                val packageName = packageInfo.packageName ?: continue

                val isSystemApp =
                    (appInfo.flags and ApplicationInfo.FLAG_SYSTEM) != 0

                if (!includeSystemApps && isSystemApp) continue

                // Skip apps without launch intent (reduces useless entries)
                if (packageManager.getLaunchIntentForPackage(packageName) == null) {
                    continue
                }

                val appName = try {
                    packageManager.getApplicationLabel(appInfo).toString()
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

                // ❌ Removed icon saving (major performance improvement)

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
            Log.e("InstalledApps", "Error: ${e.message}")
        }

        return apps.sortedBy { (it["appName"] as? String) ?: "" }
    }

    // ----------------------------
    // SCREEN TIME (OPTIMIZED)
    // ----------------------------
    private fun getScreenTime(): List<Map<String, Any?>> {

        if (!hasUsageStatsPermission()) return emptyList()

        return try {

            val usageStatsManager =
                getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager

            val calendar = Calendar.getInstance()
            calendar.set(Calendar.HOUR_OF_DAY, 0)
            calendar.set(Calendar.MINUTE, 0)
            calendar.set(Calendar.SECOND, 0)
            calendar.set(Calendar.MILLISECOND, 0)

            val startTime = calendar.timeInMillis
            val endTime = System.currentTimeMillis()

            val stats =
                usageStatsManager.queryAndAggregateUsageStats(startTime, endTime)

            val packageManager = packageManager

            stats.values
                .filter { it.totalTimeInForeground > 0L }
                .mapNotNull { usageStats ->

                    val packageName = usageStats.packageName

                    try {
                        val launchIntent =
                            packageManager.getLaunchIntentForPackage(packageName)
                                ?: return@mapNotNull null

                        val appInfo =
                            packageManager.getApplicationInfo(packageName, 0)

                        val appName = try {
                            packageManager.getApplicationLabel(appInfo).toString()
                        } catch (e: Exception) {
                            packageName
                        }

                        mapOf(
                            "package" to packageName,
                            "appName" to appName,
                            "seconds" to (usageStats.totalTimeInForeground / 1000).toInt(),
                            "lastTimeUsed" to usageStats.lastTimeUsed
                        )

                    } catch (e: Exception) {
                        null
                    }
                }
                .sortedByDescending { (it["seconds"] as? Int) ?: 0 }
                .take(20)

        } catch (e: Exception) {
            Log.e("ScreenTime", "Error: ${e.message}")
            emptyList()
        }
    }

    // ----------------------------
    // USAGE PERMISSION CHECK
    // ----------------------------
    private fun hasUsageStatsPermission(): Boolean {

        val appOps =
            getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager

        val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            appOps.unsafeCheckOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                Process.myUid(),
                packageName
            )
        } else {
            @Suppress("DEPRECATION")
            appOps.checkOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                Process.myUid(),
                packageName
            )
        }

        return mode == AppOpsManager.MODE_ALLOWED
    }
}
