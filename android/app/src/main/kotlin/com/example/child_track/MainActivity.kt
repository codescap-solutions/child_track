package com.truenyx.naviqandroid

import android.content.Intent
import android.os.Bundle
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    companion object {
        private const val TAG = "MainActivity"
        private const val GEOFENCE_CHANNEL = "com.truenyx.naviq/geofence"
        private const val BACKGROUND_LOCATION_CHANNEL = "com.truenyx.naviq/background_location"
    }

    private var deviceInfoPlugin: DeviceInfoPlugin? = null
    private val handler = android.os.Handler(android.os.Looper.getMainLooper())
    private var pendingBlockRunnable: Runnable? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        var plugin = flutterEngine.plugins.get(DeviceInfoPlugin::class.java) as? DeviceInfoPlugin
        if (plugin == null) {
            Log.w(TAG, ">>> DeviceInfoPlugin not found in registry, registering manually")
            plugin = DeviceInfoPlugin()
            flutterEngine.plugins.add(plugin)
        } else {
            Log.d(TAG, ">>> DeviceInfoPlugin resolved from registry successfully")
        }
        deviceInfoPlugin = plugin

        setupGeofenceChannel(flutterEngine)
        setupBackgroundLocationChannel(flutterEngine)
    }

    /**
     * Arms/disarms the native FusedLocationProviderClient + PendingIntent
     * background ping (NativeLocationPingManager) and its WorkManager watchdog.
     * Called from Dart's BackgroundLocationService.start()/stop() alongside the
     * foreground service, so both layers turn on/off together.
     */
    private fun setupBackgroundLocationChannel(flutterEngine: FlutterEngine) {
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, BACKGROUND_LOCATION_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "start" -> {
                        NativeLocationPingManager.start(applicationContext)
                        LocationWatchdogWorker.schedule(applicationContext)
                        result.success(true)
                    }
                    "stop" -> {
                        NativeLocationPingManager.stop(applicationContext)
                        LocationWatchdogWorker.cancel(applicationContext)
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    /**
     * Same channel name/method shape as iOS's setupGeofenceMethodChannel in
     * AppDelegate.swift, so local_geofence_engine.dart's Dart code is identical
     * across platforms — only the platform guard around the call site differs.
     */
    private fun setupGeofenceChannel(flutterEngine: FlutterEngine) {
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, GEOFENCE_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "syncGeofences" -> {
                        @Suppress("UNCHECKED_CAST")
                        val args = call.arguments as? List<Map<String, Any?>>
                        if (args == null) {
                            result.error("INVALID_ARGS", "Expected list of geofences", null)
                        } else {
                            NativeGeofenceManager.syncGeofences(applicationContext, args)
                            result.success(true)
                        }
                    }
                    "fetchGeofences" -> {
                        // Android relies on the existing Dart-side periodic refresh
                        // (LocationStateMachine._refreshGeofences) to fetch and push the
                        // list here via syncGeofences — no separate native fetch needed.
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
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
                    deviceInfoPlugin?.sendAppBlockedEvent(packageName)
                    pendingBlockRunnable = null
                }
                pendingBlockRunnable = runnable
                handler.postDelayed(runnable, 1500)
            } else {
                Log.d(TAG, ">>> Warm launch — sending appBlocked to Flutter NOW for: $packageName")
                deviceInfoPlugin?.sendAppBlockedEvent(packageName)
            }

            // Clear extras
            intent.removeExtra("app_blocked")
            intent.removeExtra("blocked_package")
        } else {
            Log.d(TAG, ">>> No block extras in intent — skipping and sending clear event")
            deviceInfoPlugin?.sendClearBlockEvent()
        }
    }
}
