package com.truenyx.naviq

import android.content.Intent
import android.os.Bundle
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {

    companion object {
        private const val TAG = "MainActivity"
    }

    private val deviceInfoPlugin = DeviceInfoPlugin()
    private val handler = android.os.Handler(android.os.Looper.getMainLooper())
    private var pendingBlockRunnable: Runnable? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        flutterEngine.plugins.add(deviceInfoPlugin)
        Log.d(TAG, "FlutterEngine configured, DeviceInfoPlugin registered")
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        Log.d(TAG, "onCreate called, intent action=${intent.action}, extras=${intent.extras}")
        handleBlockedIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        Log.d(TAG, "onNewIntent called, action=${intent.action}, extras=${intent.extras}")
        handleBlockedIntent(intent)
    }

    private fun handleBlockedIntent(intent: Intent) {
        val isBlocked = intent.getBooleanExtra("app_blocked", false)
        val packageName = intent.getStringExtra("blocked_package")

        Log.d(TAG, "handleBlockedIntent: isBlocked=$isBlocked, package=$packageName")

        if (isBlocked && packageName != null) {
            Log.d(TAG, "Sending appBlocked event to Flutter for: $packageName")

            // Cancel any previously pending block event — prevents duplicate
            // Flutter navigations when onNewIntent fires multiple times rapidly.
            pendingBlockRunnable?.let { handler.removeCallbacks(it) }

            val runnable = Runnable {
                deviceInfoPlugin.sendAppBlockedEvent(packageName)
                Log.d(TAG, "appBlocked event sent to Flutter")
                pendingBlockRunnable = null
            }
            pendingBlockRunnable = runnable
            handler.postDelayed(runnable, 1500)

            // Clear the extras so we don't re-trigger on config changes
            intent.removeExtra("app_blocked")
            intent.removeExtra("blocked_package")
        }
    }
}
