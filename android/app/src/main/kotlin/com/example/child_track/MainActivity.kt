package com.truenyx.naviq

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {

    private val deviceInfoPlugin = DeviceInfoPlugin()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        flutterEngine.plugins.add(deviceInfoPlugin)
    }

    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        super.onCreate(savedInstanceState)
        handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent) {
        if (intent.action == "com.truenyx.naviq.APP_BLOCKED") {
            val packageName = intent.getStringExtra("blocked_package")
            if (packageName != null) {
                // Delay slightly to ensure Flutter engine is ready if cold start
                android.os.Handler(android.os.Looper.getMainLooper()).postDelayed({
                    deviceInfoPlugin.sendAppBlockedEvent(packageName)
                }, 1000)
            }
        }
    }
}
