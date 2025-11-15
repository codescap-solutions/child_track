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
    // TODO: Consider reading from Info.plist or environment variable for better security
    GMSServices.provideAPIKey("AIzaSyDEI8zQzcoJQ833eangJ-dUqldtyy3OwZg")
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
