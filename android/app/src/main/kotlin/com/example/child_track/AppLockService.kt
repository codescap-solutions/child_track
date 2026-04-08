package com.truenyx.naviq

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.provider.Settings
import android.text.TextUtils
import android.util.Log
import android.view.accessibility.AccessibilityEvent

/**
 * AccessibilityService that monitors foreground app changes and blocks
 * apps whose package names are in the [lockedPackages] set.
 *
 * When a locked app is detected:
 * 1. Immediately performs GLOBAL_ACTION_BACK to dismiss it.
 * 2. Launches MainActivity with an "app_blocked" extra so the Flutter
 *    side can display the "App Blocked" screen.
 *
 * The [lockedPackages] set is updated from Flutter via DeviceInfoPlugin's
 * "updateLockList" MethodChannel call.
 */
class AppLockService : AccessibilityService() {

    companion object {
        private const val TAG = "AppLockService"
        private const val FLUTTER_PREFS_NAME = "FlutterSharedPreferences"
        // Read the CSV string we now save from Flutter
        private const val FLUTTER_PREFS_CSV_KEY = "flutter.locked_packages_csv"

        /**
         * Thread-safe set of package names currently blocked.
         * Updated from [DeviceInfoPlugin] when Flutter calls "updateLockList",
         * AND periodically refreshed from SharedPreferences.
         */
        @Volatile
        var lockedPackages: Set<String> = emptySet()
            private set

        /**
         * Replace the entire locked-packages set (called from DeviceInfoPlugin).
         * Also persists to SharedPreferences for cross-process access.
         */
        fun updateLockedPackages(packages: Set<String>, context: android.content.Context? = null) {
            lockedPackages = packages
            Log.d(TAG, ">>> Locked packages updated (MethodChannel): $packages")
            
            // Write as a comma-separated string to match Flutter's CSV writing logic
            context?.let {
                try {
                    val prefs = it.getSharedPreferences(FLUTTER_PREFS_NAME, android.content.Context.MODE_PRIVATE)
                    val csv = packages.joinToString(",")
                    prefs.edit().putString(FLUTTER_PREFS_CSV_KEY, csv).apply()
                } catch (e: Exception) {
                    Log.e(TAG, "Failed to write locked packages to prefs: ${e.message}")
                }
            }
        }

        /**
         * Check whether this AccessibilityService is currently enabled
         * in the device's accessibility settings.
         */
        fun isServiceEnabled(context: Context): Boolean {
            val expectedComponent = ComponentName(context, AppLockService::class.java)
            val enabledServices = Settings.Secure.getString(
                context.contentResolver,
                Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
            ) ?: return false

            val colonSplitter = TextUtils.SimpleStringSplitter(':')
            colonSplitter.setString(enabledServices)
            while (colonSplitter.hasNext()) {
                val componentStr = colonSplitter.next()
                val enabledComponent = ComponentName.unflattenFromString(componentStr)
                if (enabledComponent != null && enabledComponent == expectedComponent) {
                    return true
                }
            }
            return false
        }
    }

    // Track the last time we refreshed from SharedPreferences
    private var lastPrefsRefreshTime: Long = 0L
    private val PREFS_REFRESH_INTERVAL_MS = 3000L  // refresh from prefs every 3s

    // Track the last blocked package to avoid spamming intents.
    private var lastBlockedPackage: String? = null
    private var lastBlockedTime: Long = 0L
    // 1.5 s is enough to suppress re-triggers from the window events
    // that our own activity launch generates.
    private val BLOCK_DEBOUNCE_MS = 1500L

    override fun onServiceConnected() {
        super.onServiceConnected()
        Log.d(TAG, ">>> AppLockService connected (v7 — SharedPrefs sync)")

        val info = AccessibilityServiceInfo().apply {
            eventTypes = AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED
            feedbackType = AccessibilityServiceInfo.FEEDBACK_GENERIC
            notificationTimeout = 100L
            flags = AccessibilityServiceInfo.DEFAULT
        }
        serviceInfo = info

        // Load locked packages from SharedPreferences on startup
        refreshLockedPackagesFromPrefs()
    }

    /**
     * Re-reads the locked packages list from SharedPreferences.
     * Flutter's background FCM handler writes here when it can't use MethodChannel.
     */
    private fun refreshLockedPackagesFromPrefs() {
        try {
            val prefs = applicationContext.getSharedPreferences(
                FLUTTER_PREFS_NAME, android.content.Context.MODE_PRIVATE
            )
            val csv = prefs.getString(FLUTTER_PREFS_CSV_KEY, null)
            if (csv != null) {
                // If it's empty, split(",") returns [""] so we filter out blanks
                val savedPackages = if (csv.isBlank()) emptySet() else csv.split(",").toSet()
                if (savedPackages != lockedPackages) {
                    lockedPackages = savedPackages
                    Log.d(TAG, ">>> Refreshed locked packages from SharedPrefs CSV: $savedPackages")
                }
            }
            lastPrefsRefreshTime = System.currentTimeMillis()
        } catch (e: Exception) {
            Log.e(TAG, ">>> Failed to read locked packages from prefs: ${e.message}")
        }
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return
        if (event.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) return

        val packageName = event.packageName?.toString() ?: return

        // Periodically refresh lock list from SharedPreferences.
        // This picks up changes written by Flutter's background FCM handler.
        val currentTime = System.currentTimeMillis()
        if (currentTime - lastPrefsRefreshTime > PREFS_REFRESH_INTERVAL_MS) {
            refreshLockedPackagesFromPrefs()
        }

        // Log EVERY window change so we can trace the full flow
        Log.d(TAG, ">>> Window changed to: $packageName (className=${event.className})")

        // Skip system UI
        if (packageName == "com.android.systemui") return

        // When NaviQ comes to foreground, reset debounce
        if (packageName == applicationContext.packageName) {
            Log.d(TAG, ">>> NaviQ is foreground — resetting debounce (was=$lastBlockedPackage)")
            lastBlockedPackage = null
            lastBlockedTime = 0L
            return
        }

        if (packageName !in lockedPackages) {
            // Not a locked app — ignore silently
            return
        }

        val now = System.currentTimeMillis()

        // Debounce check
        if (packageName == lastBlockedPackage &&
            (now - lastBlockedTime) < BLOCK_DEBOUNCE_MS
        ) {
            val elapsed = now - lastBlockedTime
            Log.d(TAG, ">>> DEBOUNCED: $packageName (${elapsed}ms < ${BLOCK_DEBOUNCE_MS}ms)")
            return
        }

        lastBlockedPackage = packageName
        lastBlockedTime = now

        Log.d(TAG, ">>> BLOCKING: $packageName — launching NaviQ intent")

        // Launch our app immediately so it covers the blocked app
        try {
            val intent = Intent(applicationContext, MainActivity::class.java).apply {
                action = "com.truenyx.naviq.APP_BLOCKED"
                addFlags(
                    Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_CLEAR_TOP or
                    Intent.FLAG_ACTIVITY_SINGLE_TOP
                )
                putExtra("app_blocked", true)
                putExtra("blocked_package", packageName)
            }
            applicationContext.startActivity(intent)
            Log.d(TAG, ">>> Intent sent successfully for: $packageName")
        } catch (e: Exception) {
            Log.e(TAG, ">>> FAILED to launch intent: ${e.message}", e)
        }
    }

    override fun onInterrupt() {
        Log.d(TAG, "AppLockService interrupted")
    }

    override fun onDestroy() {
        super.onDestroy()
        Log.d(TAG, "AppLockService destroyed")
    }
}
