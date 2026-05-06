package com.truenyx.naviqandroid

import android.app.AppOpsManager
import android.app.usage.UsageEvents
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
import android.accessibilityservice.AccessibilityServiceInfo
import android.view.accessibility.AccessibilityManager
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.util.Calendar
import java.util.concurrent.Executors
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import java.io.ByteArrayOutputStream

/**
 * FlutterPlugin for device info operations (screen time, installed apps, etc.)
 *
 * Unlike a MethodChannel in MainActivity, a FlutterPlugin auto-registers with
 * EVERY Flutter engine — including WorkManager and FCM background isolates.
 * This ensures getScreenTime() works even when the app is killed.
 */
class DeviceInfoPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {

    private lateinit var channel: MethodChannel
    private lateinit var lockEventChannel: MethodChannel
    private lateinit var context: Context
    private var activityBinding: ActivityPluginBinding? = null
    private val executor = Executors.newSingleThreadExecutor()
    private val mainHandler = Handler(Looper.getMainLooper())

    companion object {
        private const val CHANNEL_NAME = "com.truenyx.naviq/device_info"
    }

    fun sendAppBlockedEvent(packageName: String) {
        Log.d("DeviceInfoPlugin", "sendAppBlockedEvent called for: $packageName, channelInit=${::lockEventChannel.isInitialized}")
        if (::lockEventChannel.isInitialized) {
            mainHandler.post {
                Log.d("DeviceInfoPlugin", "Invoking appBlocked on lockEventChannel for: $packageName")
                lockEventChannel.invokeMethod("appBlocked", packageName)
            }
        }
    }

    fun sendClearBlockEvent() {
        Log.d("DeviceInfoPlugin", "sendClearBlockEvent called, channelInit=${::lockEventChannel.isInitialized}")
        if (::lockEventChannel.isInitialized) {
            mainHandler.post {
                Log.d("DeviceInfoPlugin", "Invoking clearBlockScreen on lockEventChannel")
                lockEventChannel.invokeMethod("clearBlockScreen", null)
            }
        }
    }

    // ─── FlutterPlugin Lifecycle ───

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, CHANNEL_NAME)
        channel.setMethodCallHandler(this)
        // Dedicated channel for sending lock events to Flutter
        lockEventChannel = MethodChannel(binding.binaryMessenger, "com.truenyx.naviq/app_lock_events")
        Log.d("DeviceInfoPlugin", "Channels initialized: device_info + app_lock_events")
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        // lockEventChannel has no handler on native side, just nullify
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

            "updateLockList" -> {
                try {
                    val packages = call.arguments<List<String>>()
                    if (packages != null) {
                        AppLockService.updateLockedPackages(packages.toSet())
                        result.success(true)
                    } else {
                        result.error("INVALID_ARGS", "Expected List<String>", null)
                    }
                } catch (e: Exception) {
                    result.error("ERROR", e.message, null)
                }
            }

            "checkAccessibilityPermission" -> {
                result.success(AppLockService.isServiceEnabled(context))
            }

            "openAccessibilitySettings" -> {
                try {
                    val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
                    intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    context.startActivity(intent)
                    result.success(true)
                } catch (e: Exception) {
                    result.error("ERROR", e.message, null)
                }
            }

            "getAppIcon" -> {
                executor.execute {
                    try {
                        val packageName = call.argument<String>("packageName") 
                        if (packageName != null) {
                            val iconBytes = getAppIconNative(packageName)
                            mainHandler.post { result.success(iconBytes) }
                        } else {
                            mainHandler.post { result.error("ERROR", "No packageName provided", null) }
                        }
                    } catch (e: Exception) {
                        mainHandler.post { result.error("ERROR", e.message, null) }
                    }
                }
            }

            "goHome" -> {
                try {
                    val intent = Intent(Intent.ACTION_MAIN)
                    intent.addCategory(Intent.CATEGORY_HOME)
                    intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
                    context.startActivity(intent)
                    result.success(true)
                } catch (e: Exception) {
                    result.error("ERROR", e.message, null)
                }
            }

            "setWebFiltering" -> {
                try {
                    val enabled = call.arguments<Boolean>() ?: false
                    setWebFiltering(enabled)
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

            // ── Use queryEvents() for precise foreground time ──
            // queryUsageStats(INTERVAL_DAILY) returns duplicate entries per
            // package, causing totalTimeInForeground to be summed multiple
            // times (inflated ~1.5-2.7x). queryEvents() gives individual
            // FOREGROUND / BACKGROUND transitions so we can compute exact time.

            val usageEvents = usageStatsManager.queryEvents(startTime, endTime)
            val event = UsageEvents.Event()

            // per-package tracking
            val foregroundStart = mutableMapOf<String, Long>()   // currently in FG since
            val totalTime = mutableMapOf<String, Long>()         // accumulated ms
            val lastUsedMap = mutableMapOf<String, Long>()       // last interaction ts

            while (usageEvents.hasNextEvent()) {
                usageEvents.getNextEvent(event)
                val pkg = event.packageName ?: continue
                val ts = event.timeStamp

                when (event.eventType) {
                    // App moved to foreground
                    UsageEvents.Event.ACTIVITY_RESUMED -> {
                        foregroundStart[pkg] = ts
                        // Track last-used regardless
                        val prev = lastUsedMap[pkg] ?: 0L
                        if (ts > prev) lastUsedMap[pkg] = ts
                    }
                    // App moved to background
                    UsageEvents.Event.ACTIVITY_PAUSED -> {
                        val start = foregroundStart.remove(pkg)
                        if (start != null && ts > start) {
                            totalTime[pkg] = (totalTime[pkg] ?: 0L) + (ts - start)
                        }
                        val prev = lastUsedMap[pkg] ?: 0L
                        if (ts > prev) lastUsedMap[pkg] = ts
                    }
                }
            }

            // Handle apps still in the foreground at query time
            for ((pkg, start) in foregroundStart) {
                if (endTime > start) {
                    totalTime[pkg] = (totalTime[pkg] ?: 0L) + (endTime - start)
                }
            }

            val pm = context.packageManager

            totalTime.entries
                .filter { it.value > 0L }
                .mapNotNull { (packageName, timeMs) ->

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

                        val seconds = (timeMs / 1000).toInt()
                        Log.d("ScreenTime", "$packageName = ${seconds}s")

                        mapOf(
                            "package" to packageName,
                            "appName" to appName,
                            "seconds" to seconds,
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

    // ─── App Icon Extraction ───

    private fun getAppIconNative(packageName: String): ByteArray? {
        return try {
            val pm = context.packageManager
            val icon: Drawable = pm.getApplicationIcon(packageName)
            val bitmap = drawableToBitmap(icon) ?: return null

            val stream = ByteArrayOutputStream()
            bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream)
            stream.toByteArray()
        } catch (e: Exception) {
            Log.e("DeviceInfoPlugin", "getAppIconNative error: ${e.message}")
            null
        }
    }

    private fun drawableToBitmap(drawable: Drawable): Bitmap? {
        if (drawable is BitmapDrawable) {
            if (drawable.bitmap != null) {
                return drawable.bitmap
            }
        }
        
        val bitmap = if (drawable.intrinsicWidth <= 0 || drawable.intrinsicHeight <= 0) {
            Bitmap.createBitmap(1, 1, Bitmap.Config.ARGB_8888)
        } else {
            Bitmap.createBitmap(drawable.intrinsicWidth, drawable.intrinsicHeight, Bitmap.Config.ARGB_8888)
        }
        
        val canvas = Canvas(bitmap)
        drawable.setBounds(0, 0, canvas.width, canvas.height)
        drawable.draw(canvas)
        return bitmap
    }

    private fun setWebFiltering(enabled: Boolean) {
        Log.d("DeviceInfoPlugin", ">>> setWebFiltering called: $enabled")
        val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        prefs.edit().putBoolean("flutter.web_filtering_enabled", enabled).apply()
        Log.d("DeviceInfoPlugin", ">>> Web filtering persisted to SharedPreferences")
    }
}
