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

        /**
         * Thread-safe set of package names currently blocked.
         * Updated from [DeviceInfoPlugin] when Flutter calls "updateLockList".
         */
        @Volatile
        var lockedPackages: Set<String> = emptySet()
            private set

        /**
         * Replace the entire locked-packages set (called from DeviceInfoPlugin).
         */
        fun updateLockedPackages(packages: Set<String>) {
            lockedPackages = packages
            Log.d(TAG, "Locked packages updated: $packages")
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

    // Track the last blocked package to avoid spamming intents.
    // 3 s debounce: long enough to suppress re-triggers from the window
    // events that GLOBAL_ACTION_BACK itself generates.
    private var lastBlockedPackage: String? = null
    private var lastBlockedTime: Long = 0L
    private val BLOCK_DEBOUNCE_MS = 3000L

    override fun onServiceConnected() {
        super.onServiceConnected()
        Log.d(TAG, "AppLockService connected")

        val info = AccessibilityServiceInfo().apply {
            eventTypes = AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED
            feedbackType = AccessibilityServiceInfo.FEEDBACK_GENERIC
            notificationTimeout = 100L
            flags = AccessibilityServiceInfo.DEFAULT
        }
        serviceInfo = info
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return
        if (event.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) return

        val packageName = event.packageName?.toString() ?: return

        // Never block ourselves or system UI.
        // IMPORTANT: if naviq is already in the foreground (e.g. showing the
        // AppBlockedScreen) we must NOT perform GLOBAL_ACTION_BACK — that
        // would dismiss our own blocking UI.
        if (packageName == applicationContext.packageName) return
        if (packageName == "com.android.systemui") return

        if (packageName !in lockedPackages) return

        val now = System.currentTimeMillis()

        // Debounce: ignore repeated events for the same package within the window.
        if (packageName == lastBlockedPackage &&
            (now - lastBlockedTime) < BLOCK_DEBOUNCE_MS
        ) {
            Log.d(TAG, "Debounced duplicate block for: $packageName")
            return
        }

        lastBlockedPackage = packageName
        lastBlockedTime = now

        Log.d(TAG, "Blocking app: $packageName")

        // 1. Press Back to dismiss the locked app from foreground.
        performGlobalAction(GLOBAL_ACTION_BACK)

        // 2. Launch our app with the "app_blocked" flag.
        //    FLAG_ACTIVITY_SINGLE_TOP ensures onNewIntent is called (not onCreate)
        //    if MainActivity is already on top, preventing duplicate instances.
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
    }

    override fun onInterrupt() {
        Log.d(TAG, "AppLockService interrupted")
    }

    override fun onDestroy() {
        super.onDestroy()
        Log.d(TAG, "AppLockService destroyed")
    }
}
