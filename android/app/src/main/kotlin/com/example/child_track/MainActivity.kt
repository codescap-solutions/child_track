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
        setIntent(intent) // Update the stored intent
        Log.d(TAG, "onNewIntent called, action=${intent.action}, extras=${intent.extras}")
        handleBlockedIntent(intent)
    }

    private fun handleBlockedIntent(intent: Intent) {
        // Check via boolean extra (always set by AppLockService)
        val isBlocked = intent.getBooleanExtra("app_blocked", false)
        val packageName = intent.getStringExtra("blocked_package")

        Log.d(TAG, "handleBlockedIntent: isBlocked=$isBlocked, package=$packageName")

        if (isBlocked && packageName != null) {
            Log.d(TAG, "Sending appBlocked event to Flutter for: $packageName")
            // Delay to ensure Flutter engine and MethodChannel are ready
            android.os.Handler(android.os.Looper.getMainLooper()).postDelayed({
                deviceInfoPlugin.sendAppBlockedEvent(packageName)
                Log.d(TAG, "appBlocked event sent to Flutter")
            }, 500)

            // Clear the extras so we don't re-trigger on config changes
            intent.removeExtra("app_blocked")
            intent.removeExtra("blocked_package")
        }
    }
}
