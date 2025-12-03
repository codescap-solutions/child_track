import Flutter
import UIKit
import GoogleMaps
import AVFoundation

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
    
    // Setup method channel for device info after plugins are registered
    if let controller = window?.rootViewController as? FlutterViewController {
      let deviceInfoChannel = FlutterMethodChannel(
        name: "com.example.child_track/device_info",
        binaryMessenger: controller.binaryMessenger
      )
      
      deviceInfoChannel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
        if call.method == "getSoundProfile" {
          let soundProfile = self.getSoundProfile()
          result(soundProfile)
        } else if call.method == "getInstalledApps" {
          let apps = self.getInstalledApps()
          result(apps)
        } else {
          result(FlutterMethodNotImplemented)
        }
      }
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  private func getSoundProfile() -> String {
    // On iOS, detecting the silent switch state is limited
    // iOS doesn't provide a direct API to check the silent switch
    // We can check the audio session state and volume
    do {
      let audioSession = AVAudioSession.sharedInstance()
      try audioSession.setActive(true)
      
      // Check output volume
      let volume = audioSession.outputVolume
      
      // iOS doesn't expose silent switch state directly through public APIs
      // The silent switch is a hardware switch that affects ringer volume
      // We can check if the audio session category allows sound
      let category = audioSession.category
      
      // If category is set to ambient or playback, it's likely in sound mode
      // If we can't determine, we'll default to "sound"
      // Note: This is a limitation of iOS - the silent switch state
      // cannot be directly queried through public APIs
      
      if category == .ambient || category == .playback || category == .playAndRecord {
        return volume > 0 ? "sound" : "sound" // Default to sound as iOS limitation
      } else {
        return "sound" // Default assumption
      }
    } catch {
      // On error, default to "sound"
      return "sound"
    }
  }
  
  private func getInstalledApps() -> [[String: Any?]] {
    // Note: iOS has strict privacy restrictions and doesn't allow apps
    // to query all installed apps. This is a limitation of iOS.
    // We can only check for specific apps using URL schemes.
    
    // For iOS, we'll return an empty array or try to detect some common apps
    // using URL scheme checking. However, this is limited.
    var apps: [[String: Any?]] = []
    
    // Common apps we can check via URL schemes
    let commonApps: [(name: String, scheme: String, packageName: String)] = [
      ("Settings", "prefs:", "com.apple.Preferences"),
      ("Safari", "http://", "com.apple.mobilesafari"),
      ("Mail", "mailto:", "com.apple.mobilemail"),
      ("Messages", "sms:", "com.apple.MobileSMS"),
      ("Phone", "tel:", "com.apple.mobilephone"),
      ("Camera", "camera:", "com.apple.camera"),
      ("Photos", "photos-redirect://", "com.apple.mobileslideshow"),
    ]
    
    for app in commonApps {
      if let url = URL(string: app.scheme) {
        if UIApplication.shared.canOpenURL(url) {
          apps.append([
            "packageName": app.packageName,
            "appName": app.name,
            "iconPath": nil,
            "isSystemApp": true,
            "versionName": nil,
            "versionCode": nil
          ])
        }
      }
    }
    
    // Note: This is a very limited list. iOS doesn't allow full app enumeration
    // due to privacy restrictions. For a complete solution, you would need
    // to use MDM (Mobile Device Management) or other enterprise solutions.
    
    return apps
  }
}
