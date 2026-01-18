package com.example.child_track

import android.content.Context
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import android.media.AudioManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream
import android.app.AppOpsManager
import android.app.usage.UsageStatsManager
import android.os.Process
import android.util.Base64
import java.io.ByteArrayOutputStream
import java.util.Calendar

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.child_track/device_info"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getSoundProfile" -> {
                    val soundProfile = getSoundProfile()
                    result.success(soundProfile)
                }
                "getInstalledApps" -> {
                    try {
                        val includeSystemApps = call.argument<Boolean>("includeSystemApps") ?: true
                        val apps = getInstalledApps(includeSystemApps)
                        result.success(apps)
                    } catch (e: Exception) {
                        result.error("ERROR", "Failed to get installed apps: ${e.message}", null)
                    }
                }
                "getScreenTime" -> {
                    Thread {
                        try {
                            val screenTime = getScreenTime()
                            runOnUiThread {
                                result.success(screenTime)
                            }
                        } catch (e: Exception) {
                            runOnUiThread {
                                result.error("ERROR", "Failed to get screen time: ${e.message}", null)
                            }
                        }
                    }.start()
                }
                "checkUsagePermission" -> {
                    result.success(hasUsageStatsPermission())
                }
                "openUsageSettings" -> {
                    try {
                        val intent = android.content.Intent(android.provider.Settings.ACTION_USAGE_ACCESS_SETTINGS)
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("ERROR", "Failed to open settings: ${e.message}", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun getSoundProfile(): String {
        val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        return when (audioManager.ringerMode) {
            AudioManager.RINGER_MODE_NORMAL -> "sound"
            AudioManager.RINGER_MODE_VIBRATE -> "vibrate"
            AudioManager.RINGER_MODE_SILENT -> "silent"
            else -> "unknown"
        }
    }

    private fun getInstalledApps(includeSystemApps: Boolean): List<Map<String, Any?>> {
        val apps = mutableListOf<Map<String, Any?>>()
        
        try {
            val packageManager = packageManager ?: return apps
            val packages = packageManager.getInstalledPackages(PackageManager.GET_META_DATA) ?: return apps
            
            for (packageInfo in packages) {
                try {
                    val appInfo = packageInfo.applicationInfo ?: continue
                    val packageName = packageInfo.packageName ?: continue
                    
                    // Get app name safely
                    val appName = try {
                        packageManager.getApplicationLabel(appInfo).toString()
                    } catch (e: Exception) {
                        packageName // Fallback to package name
                    }
                    
                    val isSystemApp = (appInfo.flags and ApplicationInfo.FLAG_SYSTEM) != 0

                    if (!includeSystemApps && isSystemApp) {
                        continue
                    }

                    val versionName = packageInfo.versionName
                    val versionCode = try {
                        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.P) {
                            packageInfo.longVersionCode.toInt()
                        } else {
                            @Suppress("DEPRECATION")
                            packageInfo.versionCode
                        }
                    } catch (e: Exception) {
                        null
                    }
                    
                    // Get app icon and save it
                    val iconPath = try {
                        val icon = appInfo.loadIcon(packageManager)
                        saveAppIcon(icon, packageName)
                    } catch (e: Exception) {
                        null
                    }
                    
                    apps.add(mapOf(
                        "packageName" to packageName,
                        "appName" to appName,
                        "iconPath" to iconPath,
                        "isSystemApp" to isSystemApp,
                        "versionName" to versionName,
                        "versionCode" to versionCode
                    ))
                } catch (e: Exception) {
                    // Skip apps that can't be processed
                    continue
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
        
        // Sort by app name
        return try {
            apps.sortedBy { (it["appName"] as? String) ?: "" }
        } catch (e: Exception) {
            apps
        }
    }

    private fun saveAppIcon(drawable: Drawable, packageName: String): String? {
        return try {
            val bitmap = drawableToBitmap(drawable) ?: return null
            val cacheDir = cacheDir
            val iconDir = File(cacheDir, "app_icons")
            if (!iconDir.exists()) {
                iconDir.mkdirs()
            }
            
            val iconFile = File(iconDir, "${packageName.replace(".", "_")}.png")
            FileOutputStream(iconFile).use { out ->
                bitmap.compress(Bitmap.CompressFormat.PNG, 100, out)
            }
            iconFile.absolutePath
        } catch (e: Exception) {
            null
        }
    }

    private fun drawableToBitmap(drawable: Drawable): Bitmap? {
        return try {
            if (drawable is BitmapDrawable && drawable.bitmap != null) {
                return drawable.bitmap
            }
            
            val width = drawable.intrinsicWidth
            val height = drawable.intrinsicHeight
            
            // Handle zero or negative dimensions
            if (width <= 0 || height <= 0) {
                // Use default size if dimensions are invalid
                val defaultSize = 48
                val bitmap = Bitmap.createBitmap(defaultSize, defaultSize, Bitmap.Config.ARGB_8888)
                val canvas = Canvas(bitmap)
                drawable.setBounds(0, 0, defaultSize, defaultSize)
                drawable.draw(canvas)
                return bitmap
            }
            
            val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
            val canvas = Canvas(bitmap)
            drawable.setBounds(0, 0, width, height)
            drawable.draw(canvas)
            return bitmap
        } catch (e: Exception) {
            null
        }
    }
    private fun getScreenTime(): List<Map<String, Any?>> {
        if (!hasUsageStatsPermission()) {
            return emptyList()
        }

        val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val start = System.currentTimeMillis() - 1000 * 60 * 60 * 24 // 24 hours just in case, or from midnight
        // Use midnight today for daily view
        val calendar = Calendar.getInstance()
        calendar.set(Calendar.HOUR_OF_DAY, 0)
        calendar.set(Calendar.MINUTE, 0)
        calendar.set(Calendar.SECOND, 0)
        calendar.set(Calendar.MILLISECOND, 0)
        val startTime = calendar.timeInMillis
        val endTime = System.currentTimeMillis()

        val stats = usageStatsManager.queryAndAggregateUsageStats(startTime, endTime)
        val packageManager = packageManager
        
        return stats.values.mapNotNull { usageStats ->
            try {
                if (usageStats.totalTimeInForeground == 0L) return@mapNotNull null

                val packageName = usageStats.packageName
                // Filter basic system packages
                if (packageName.startsWith("com.android.") && !packageName.contains("contacts") && !packageName.contains("dialer") && !packageName.contains("settings") && !packageName.contains("vending")) {
                   // Keep play store, settings, contacts, dialer if they have usage
                   // Actually, safer to check isSystemApp
                   val appInfo = packageManager.getApplicationInfo(packageName, 0)
                   if ((appInfo.flags and ApplicationInfo.FLAG_SYSTEM) != 0 && (appInfo.flags and ApplicationInfo.FLAG_UPDATED_SYSTEM_APP) == 0) {
                       // It's a system app and not an updated one.
                       // Maybe checking launch intent is better to determine "user-facing" apps
                       if (packageManager.getLaunchIntentForPackage(packageName) == null) {
                           return@mapNotNull null
                       }
                   }
                }
                
                // Get app name
                val appName = try {
                    val appInfo = packageManager.getApplicationInfo(packageName, 0)
                    packageManager.getApplicationLabel(appInfo).toString()
                } catch (e: Exception) {
                    packageName
                }

                mapOf(
                    "package" to packageName,
                    "appName" to appName,
                    "seconds" to (usageStats.totalTimeInForeground / 1000).toInt(),
                    "lastTimeUsed" to usageStats.lastTimeUsed,
                    "icon" to getAppIconBase64(packageName)
                )
            } catch (e: Exception) {
                null
            }
        }.sortedByDescending { it["seconds"] as Int }
    }

    private fun getAppIconBase64(packageName: String): String? {
        return try {
            val packageManager = packageManager
            val appInfo = packageManager.getApplicationInfo(packageName, 0)
            val iconDrawable = appInfo.loadIcon(packageManager)
            
            // Convert to bitmap
            val originalBitmap = drawableToBitmap(iconDrawable) ?: return null
            
            // Resize to 64x64
            val scaledBitmap = Bitmap.createScaledBitmap(originalBitmap, 64, 64, true)
            
            // Compress to PNG
            val byteArrayOutputStream = ByteArrayOutputStream()
            scaledBitmap.compress(Bitmap.CompressFormat.PNG, 100, byteArrayOutputStream)
            val byteArray = byteArrayOutputStream.toByteArray()
            
            // Encode to Base64
            Base64.encodeToString(byteArray, Base64.NO_WRAP)
        } catch (e: Exception) {
            null
        }
    }

    private fun hasUsageStatsPermission(): Boolean {
        val appOps = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.Q) {
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
