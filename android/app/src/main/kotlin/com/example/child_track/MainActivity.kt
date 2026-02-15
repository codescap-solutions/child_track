package com.truenyx.naviq

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Register DeviceInfoPlugin so the MethodChannel is available
        // in the main app's Flutter engine.
        // For background isolates (WorkManager, FCM), the plugin is
        // auto-registered via GeneratedPluginRegistrant.
        flutterEngine.plugins.add(DeviceInfoPlugin())
    }
}
