import Flutter
import UIKit
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Google Maps API Key is automatically injected from .env file via Podfile post_install hook
    // The key below is updated automatically when you run 'pod install'
    GMSServices.provideAPIKey("AIzaSyASaOyJsO7dp01jjv625MI9Tw9HwEeTuQg")
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
