import Flutter
import UIKit
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // NOTE: This key should match the GOOGLE_MAPS_API_KEY in your .env file
    // For iOS, you need to manually update this key to match your .env file
    // TODO: Consider reading from Info.plist or using build configurations for better security
    GMSServices.provideAPIKey("AIzaSyASaOyJsO7dp01jjv625MI9Tw9HwEeTuQg")
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
