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
        Log.d(TAG, ">>> FlutterEngine configured, DeviceInfoPlugin registered")
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        Log.d(TAG, ">>> onCreate called")
        Log.d(TAG, ">>>   action=${intent.action}")
        Log.d(TAG, ">>>   extras=${intent.extras}")
        Log.d(TAG, ">>>   app_blocked=${intent.getBooleanExtra("app_blocked", false)}")
        Log.d(TAG, ">>>   blocked_package=${intent.getStringExtra("blocked_package")}")
        // Cold launch: Flutter engine needs time to warm up
        handleBlockedIntent(intent, isColdLaunch = true)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        Log.d(TAG, ">>> onNewIntent called")
        Log.d(TAG, ">>>   action=${intent.action}")
        Log.d(TAG, ">>>   app_blocked=${intent.getBooleanExtra("app_blocked", false)}")
        Log.d(TAG, ">>>   blocked_package=${intent.getStringExtra("blocked_package")}")
        // Warm launch: Flutter already running
        handleBlockedIntent(intent, isColdLaunch = false)
    }

    override fun onResume() {
        super.onResume()
        Log.d(TAG, ">>> onResume called")
    }

    private fun handleBlockedIntent(intent: Intent, isColdLaunch: Boolean = true) {
        val isBlocked = intent.getBooleanExtra("app_blocked", false)
        val packageName = intent.getStringExtra("blocked_package")

        Log.d(TAG, ">>> handleBlockedIntent: blocked=$isBlocked, pkg=$packageName, cold=$isColdLaunch")

        if (isBlocked && packageName != null) {
            // Cancel any previously pending block event
            pendingBlockRunnable?.let {
                handler.removeCallbacks(it)
                Log.d(TAG, ">>> Cancelled previous pending block")
            }
            pendingBlockRunnable = null

            if (isColdLaunch) {
                Log.d(TAG, ">>> Cold launch — scheduling appBlocked with 1500ms delay")
                val runnable = Runnable {
                    Log.d(TAG, ">>> [1500ms elapsed] Sending appBlocked to Flutter for: $packageName")
                    deviceInfoPlugin.sendAppBlockedEvent(packageName)
                    pendingBlockRunnable = null
                }
                pendingBlockRunnable = runnable
                handler.postDelayed(runnable, 1500)
            } else {
                Log.d(TAG, ">>> Warm launch — sending appBlocked to Flutter NOW for: $packageName")
                deviceInfoPlugin.sendAppBlockedEvent(packageName)
            }

            // Clear extras
            intent.removeExtra("app_blocked")
            intent.removeExtra("blocked_package")
        } else {
            Log.d(TAG, ">>> No block extras in intent — skipping and sending clear event")
            deviceInfoPlugin.sendClearBlockEvent()
        }
    }
}
