package com.truenyx.naviqandroid

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.provider.Settings
import android.text.TextUtils
import android.util.Log
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo
import java.util.Locale

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
        private const val FLUTTER_PREFS_WEB_FILTER_KEY = "flutter.web_filtering_enabled"

        private val BROWSER_PACKAGES = setOf(
            "com.android.chrome",
            "org.mozilla.firefox",
            "com.sec.android.app.sbrowser", // Samsung Browser
            "com.opera.browser",
            "com.opera.mini.native",
            "com.microsoft.emmx", // Edge
            "com.duckduckgo.mobile.android"
        )

        private val BLOCKED_KEYWORDS = setOf(
            "porn", "xxx", "sex", "adult", "xvideo", "pornhub", "redtube", "brazzers", "xhamster"
        )

        /**
         * Thread-safe set of package names currently blocked.
         * Updated from [DeviceInfoPlugin] when Flutter calls "updateLockList",
         * AND periodically refreshed from SharedPreferences.
         */
        @Volatile
        var lockedPackages: Set<String> = emptySet()
            private set

        @Volatile
        var webFilteringEnabled: Boolean = false
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
    private val PREFS_REFRESH_INTERVAL_MS = 5000L  // refresh from prefs every 5s

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
            eventTypes = AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED or 
                         AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED
            feedbackType = AccessibilityServiceInfo.FEEDBACK_GENERIC
            notificationTimeout = 100L
            flags = AccessibilityServiceInfo.DEFAULT or 
                    AccessibilityServiceInfo.FLAG_RETRIEVE_INTERACTIVE_WINDOWS
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
            
            val webEnabled = prefs.getBoolean(FLUTTER_PREFS_WEB_FILTER_KEY, false)
            if (webEnabled != webFilteringEnabled) {
                webFilteringEnabled = webEnabled
                Log.d(TAG, ">>> Web filtering status updated: $webEnabled")
            }

            lastPrefsRefreshTime = System.currentTimeMillis()
        } catch (e: Exception) {
            Log.e(TAG, ">>> Failed to read locked packages from prefs: ${e.message}")
        }
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return
        
        val eventType = event.eventType
        val packageName = event.packageName?.toString() ?: return

        // Periodically refresh settings from SharedPreferences.
        // This picks up changes written by Flutter's background FCM handler.
        val currentTime = System.currentTimeMillis()
        if (currentTime - lastPrefsRefreshTime > PREFS_REFRESH_INTERVAL_MS) {
            refreshLockedPackagesFromPrefs()
        }

        // Log window changes
        if (eventType == AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) {
            Log.d(TAG, ">>> Window changed to: $packageName (className=${event.className})")
        }

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
            // If web filtering is enabled and it's a browser, check the URL
            if (webFilteringEnabled && BROWSER_PACKAGES.contains(packageName)) {
                checkWebFiltering(packageName)
            }
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
                action = "com.truenyx.naviqandroid.APP_BLOCKED"
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

    /**
     * Scans the browser's node hierarchy to find and check the URL.
     */
    private fun checkWebFiltering(packageName: String) {
        val rootNode = rootInActiveWindow ?: return
        
        // Find URL/Address bar
        val url = findUrlInNodes(rootNode)
        rootNode.recycle()

        if (url != null) {
            val lowerUrl = url.lowercase(Locale.ROOT)
            for (keyword in BLOCKED_KEYWORDS) {
                if (lowerUrl.contains(keyword)) {
                    Log.d(TAG, ">>> WEB FILTER BLOCKED: $url (keyword: $keyword)")
                    triggerBlock(packageName, url)
                    break
                }
            }
        }
    }

    private fun findUrlInNodes(node: AccessibilityNodeInfo): String? {
        // Look for nodes that look like address bars (usually have some text and are editable or have specific IDs)
        // Note: Different browsers have different resource IDs. We'll check text content for common patterns.
        
        val text = node.text?.toString()
        if (text != null && (text.contains(".") || text.contains("http"))) {
            // Heuristic: if it's an address bar, it usually doesn't have many children and is near the top
            // This is a simplified check.
            if (node.isEditable || node.className?.contains("EditText") == true) {
                return text
            }
        }

        for (i in 0 until node.childCount) {
            val child = node.getChild(i) ?: continue
            val result = findUrlInNodes(child)
            child.recycle()
            if (result != null) return result
        }
        return null
    }

    private fun triggerBlock(packageName: String, url: String) {
        val now = System.currentTimeMillis()
        if (packageName == lastBlockedPackage && (now - lastBlockedTime) < BLOCK_DEBOUNCE_MS) return
        
        lastBlockedPackage = packageName
        lastBlockedTime = now

        try {
            val intent = Intent(applicationContext, MainActivity::class.java).apply {
                action = "com.truenyx.naviqandroid.APP_BLOCKED"
                addFlags(
                    Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_CLEAR_TOP or
                    Intent.FLAG_ACTIVITY_SINGLE_TOP
                )
                putExtra("app_blocked", true)
                putExtra("blocked_package", packageName)
                putExtra("blocked_url", url)
            }
            applicationContext.startActivity(intent)
        } catch (e: Exception) {
            Log.e(TAG, ">>> FAILED to launch web block intent: ${e.message}")
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
