import Flutter
import UIKit
import GoogleMaps
import AVFoundation
import FirebaseCore
import FirebaseMessaging
import UserNotifications
import FamilyControls
import ManagedSettings
import DeviceActivity
import SwiftUI

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Initialize Firebase
    FirebaseApp.configure()
    
    // NOTE: This key should match the GOOGLE_MAPS_API_KEY in your .env file
    // For iOS, you need to manually update this key to match your .env file
    // TODO: Consider reading from Info.plist or using build configurations for better security
    GMSServices.provideAPIKey("AIzaSyASaOyJsO7dp01jjv625MI9Tw9HwEeTuQg")
    
    GeneratedPluginRegistrant.register(with: self)
    
    // Set up Firebase Messaging delegate
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
      let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
      UNUserNotificationCenter.current().requestAuthorization(
        options: authOptions,
        completionHandler: { _, _ in }
      )
    } else {
      let settings: UIUserNotificationSettings =
        UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
      application.registerUserNotificationSettings(settings)
    }
    
    application.registerForRemoteNotifications()
    
    Messaging.messaging().delegate = self
    
    // Setup method channel for device info after plugins are registered
    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    
    // Test App Group access immediately
    let suiteName = "group.com.truenyx.naviq"
    if let defaults = UserDefaults(suiteName: suiteName) {
        defaults.set(true, forKey: "com.truenyx.naviq.app_group_test")
        let success = defaults.bool(forKey: "com.truenyx.naviq.app_group_test")
        print("📱 APP GROUP TEST: \(success ? "SUCCESS ✅" : "FAILED ❌")")
    } else {
        print("📱 APP GROUP TEST: FAILED ❌ (Could not create UserDefaults for suite)")
    }

    let deviceInfoChannel = FlutterMethodChannel(
        name: "com.truenyx.naviq/device_info",
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
      
      // Setup parental control channel
      let parentalChannel = FlutterMethodChannel(
        name: "com.truenyx.naviq/parental_control",
        binaryMessenger: controller.binaryMessenger
      )
      
      parentalChannel.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
        guard let self = self else { return }
        switch call.method {
        case "requestScreenTimePermission":
          self.requestScreenTimePermission(result: result)
          
        case "checkScreenTimePermission":
          self.checkScreenTimePermission(result: result)
          
        case "updateLockList":
          if let ids = call.arguments as? [String] {
            self.updateLockList(ids: ids, result: result)
          } else {
            result(FlutterError(code: "INVALID_ARGS", message: "Expected string array", details: nil))
          }
          
        case "getScreenTime":
          self.getScreenTimeData(result: result)
          
        case "getInstalledApps":
          // Family Controls does not support enumerating all apps.
          // Returning an empty array. Parent must use FamilyActivityPicker.
          result([])
          
        case "getAppIcon":
          // Returning null as iOS opaque tokens don't allow icon extraction.
          result(nil)
          
        case "openFamilyActivityPicker":
          self.openFamilyActivityPicker(result: result)
          
        case "getMonitoredApps":
          self.getMonitoredApps(result: result)
          
        case "setWebFiltering":
          if let enabled = call.arguments as? Bool {
            self.setWebFiltering(enabled: enabled, result: result)
          } else {
            result(FlutterError(code: "INVALID_ARGS", message: "Expected boolean", details: nil))
          }
          
        default:
          result(FlutterMethodNotImplemented)
        }
      }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  // MARK: - Native Background Push Handler
  // This is called by iOS when a silent push arrives (content-available: 1).
  // It runs NATIVELY — no Flutter isolate needed. Critical for background locking.
  override func application(
    _ application: UIApplication,
    didReceiveRemoteNotification userInfo: [AnyHashable: Any],
    fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
  ) {
    let type = userInfo["type"] as? String ?? (userInfo["gcm.notification.type"] as? String)
    let action = userInfo["action"] as? String
    print("AppDelegate: didReceiveRemoteNotification type=\(type ?? "nil") action=\(action ?? "nil")")
    
    // Handle new backend format: action = "lock_apps" / "unlock_apps"
    if action == "lock_apps" || action == "unlock_apps" {
      if #available(iOS 16.0, *) {
        let tokens = parseTokensFromPayload(userInfo)
        if !tokens.isEmpty {
          if action == "lock_apps" {
            print("AppDelegate: lock_apps — adding shields for \(tokens.count) tokens")
            // Add these tokens to existing lock list
            let existing = ScreenTimeManager.shared.getLockedIds()
            let merged = Array(Set(existing + tokens))
            ScreenTimeManager.shared.applyShields(ids: merged)
          } else {
            print("AppDelegate: unlock_apps — removing shields for \(tokens.count) tokens")
            // Remove these tokens from lock list
            let existing = ScreenTimeManager.shared.getLockedIds()
            let filtered = existing.filter { !tokens.contains($0) }
            ScreenTimeManager.shared.applyShields(ids: filtered)
          }
          completionHandler(.newData)
          return
        }
      }
      // If no tokens, fetch full list from API via Dart
      completionHandler(.newData)
      return
    }
    
    // Backward compatibility: old format type = "SYNC_LOCKED_APPS"
    if type == "SYNC_LOCKED_APPS" {
      if #available(iOS 16.0, *) {
        let tokens = parseTokensFromPayload(userInfo)
        if !tokens.isEmpty {
          print("AppDelegate: SYNC_LOCKED_APPS — applying shields for \(tokens.count) tokens")
          ScreenTimeManager.shared.applyShields(ids: tokens)
          completionHandler(.newData)
          return
        }
        print("AppDelegate: SYNC_LOCKED_APPS — no tokens in payload, deferring to Flutter handler")
      }
      completionHandler(.newData)
      return
    }
    
    // For all other push types, let Flutter handle it
    super.application(application, didReceiveRemoteNotification: userInfo, fetchCompletionHandler: completionHandler)
  }
  
  // Parse tokens from FCM data payload (handles JSON array string, comma-separated, or native array)
  private func parseTokensFromPayload(_ userInfo: [AnyHashable: Any]) -> [String] {
    if let tokensStr = userInfo["tokens"] as? String, !tokensStr.isEmpty {
      // Try JSON array first: '["tok1","tok2"]'
      if let jsonData = tokensStr.data(using: .utf8),
         let jsonTokens = try? JSONSerialization.jsonObject(with: jsonData) as? [String] {
        return jsonTokens
      }
      // Fallback: comma-separated
      return tokensStr.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }
    }
    if let tokens = userInfo["tokens"] as? [String] {
      return tokens
    }
    return []
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
  
  // Handle APNS token
  override func application(_ application: UIApplication,
                            didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    Messaging.messaging().apnsToken = deviceToken
  }
  
  // Handle APNS token registration failure
  override func application(_ application: UIApplication,
                            didFailToRegisterForRemoteNotificationsWithError error: Error) {
    print("Failed to register for remote notifications: \(error)")
  }
  
  // MARK: - Parental Controls (Family Controls)
  
  private func requestScreenTimePermission(result: @escaping FlutterResult) {
    if #available(iOS 16.0, *) {
      print("DEBUG: Calling AuthorizationCenter.shared.requestAuthorization(for: .individual)")
      let center = AuthorizationCenter.shared
      print("DEBUG: Current auth status before request: \(center.authorizationStatus)")
      Task { @MainActor in
        do {
          try await center.requestAuthorization(for: .individual)
          print("DEBUG: Screen Time permission GRANTED successfully")
          // Start monitoring after permission is granted
          ScreenTimeManager.shared.startMonitoring()
          result(true)
        } catch {
          print("DEBUG: Family controls authorization FAILED. Error: \(error.localizedDescription)")
          print("DEBUG: Full error: \(error)")
          result(FlutterError(
            code: "PERMISSION_DENIED",
            message: error.localizedDescription,
            details: nil
          ))
        }
      }
    } else {
      print("DEBUG: iOS 16+ is required for Family Controls")
      result(FlutterError(code: "UNSUPPORTED_OS", message: "iOS 16+ is required", details: nil))
    }
  }

  private func checkScreenTimePermission(result: @escaping FlutterResult) {
    if #available(iOS 16.0, *) {
      let status = AuthorizationCenter.shared.authorizationStatus
      print("DEBUG: checkScreenTimePermission - authorizationStatus: \(status)")
      result(status == .approved)
    } else {
      print("DEBUG: checkScreenTimePermission - iOS < 16, returning false")
      result(false)
    }
  }

  private func getScreenTimeData(result: @escaping FlutterResult) {
    if #available(iOS 16.0, *) {
      let status = AuthorizationCenter.shared.authorizationStatus
      guard status == .approved else {
        print("DEBUG: getScreenTimeData called but permission not approved: \(status)")
        result([])
        return
      }

      // Print extension logs for debugging
      let extLogs = ScreenTimeManager.shared.getExtensionLogs()
      for log in extLogs {
          print("📱 EXT LOG: \(log)")
      }
      
      // Read usage data accumulated by the DeviceActivityMonitor extension
      let records = ScreenTimeManager.shared.getAccumulatedUsage()
      print("DEBUG: getScreenTimeData returning \(records.count) records")
      
      if records.isEmpty {
        print("DEBUG: No usage records accumulated yet from DeviceActivity extension")
        result([])
        return
      }
      
      result(records)
    } else {
      print("DEBUG: getScreenTimeData - iOS < 16")
      result([])
    }
  }
  
  private func openFamilyActivityPicker(result: @escaping FlutterResult) {
    if #available(iOS 16.0, *) {
      let center = AuthorizationCenter.shared
      
      // Auto-request authorization if not already approved
      if center.authorizationStatus != .approved {
        print("AppDelegate: Not authorized. Requesting Screen Time permission first...")
        Task { @MainActor in
          do {
            try await center.requestAuthorization(for: .individual)
            print("AppDelegate: Authorization granted. Proceeding to picker...")
            self.presentPicker(result: result)
          } catch {
            print("AppDelegate: Authorization failed: \(error.localizedDescription)")
            result(FlutterError(code: "AUTH_FAILED", message: error.localizedDescription, details: nil))
          }
        }
      } else {
        print("AppDelegate: Already authorized. Presenting picker...")
        DispatchQueue.main.async {
          self.presentPicker(result: result)
        }
      }
    } else {
      result(FlutterError(code: "UNSUPPORTED_OS", message: "iOS 16.0+ required", details: nil))
    }
  }

  @available(iOS 16.0, *)
  private func presentPicker(result: @escaping FlutterResult) {
    guard let controller = self.window?.rootViewController else {
      result(FlutterError(code: "NO_CONTROLLER", message: "Root view controller not found", details: nil))
      return
    }
    
    let pickerVC = FamilyActivityPickerController()
    pickerVC.onComplete = { tokens in
      print("AppDelegate: Picker completed with \(tokens.count) tokens")
      result(tokens)
    }
    
    controller.present(pickerVC, animated: true)
  }

  private func updateLockList(ids: [String], result: @escaping FlutterResult) {
    if #available(iOS 16.0, *) {
      ScreenTimeManager.shared.applyShields(ids: ids)
      result(true)
    } else {
      result(false)
    }
  }

  private func getMonitoredApps(result: @escaping FlutterResult) {
    if #available(iOS 16.0, *) {
      let defaults = UserDefaults(suiteName: "group.com.truenyx.naviq")
      guard let data = defaults?.data(forKey: "com.truenyx.naviq.token_map"),
            let map = try? JSONSerialization.jsonObject(with: data) as? [String: [String: Any]] else {
        result([])
        return
      }
      // Return as list of {id, type, displayName}
      let items = map.values.map { $0 }
      result(Array(items))
    } else {
      result([])
    }
  }

  private func setWebFiltering(enabled: Bool, result: @escaping FlutterResult) {
    print("AppDelegate: setWebFiltering called with value: \(enabled)")
    if #available(iOS 16.0, *) {
      ScreenTimeManager.shared.applyWebContentFilter(enabled: enabled)
      result(true)
    } else {
      print("AppDelegate: setWebFiltering FAILED - OS version too low")
      result(FlutterError(code: "UNSUPPORTED_OS", message: "iOS 16+ required", details: nil))
    }
  }
}

// MARK: - ScreenTimeManager
// Manages Screen Time monitoring and data accumulation via App Group shared storage.
@available(iOS 16.0, *)
class ScreenTimeManager {
    static let shared = ScreenTimeManager()
    private let appGroupID = "group.com.truenyx.naviq"
    private let usageKey = "com.truenyx.naviq.screentime_data"
    private let monitorName = DeviceActivityName("com.truenyx.naviq.daily")
    private var sharedDefaults: UserDefaults? { UserDefaults(suiteName: appGroupID) }
    private init() {}
    
    // Production thresholds: Strategic intervals for accurate tracking
    // 12 thresholds per app/category — stays under Apple's ~100 event limit
    private let thresholds = [
        60,    // 1 min — first detection
        120,   // 2 min
        300,   // 5 min
        600,   // 10 min
        900,   // 15 min
        1800,  // 30 min
        3600,  // 1 hour
        5400,  // 1.5 hours
        7200,  // 2 hours
        10800, // 3 hours
        14400, // 4 hours
        21600, // 6 hours
    ]
    
    // Apple limits events to roughly 100 per startMonitoring call
    private let maxEvents = 100
    
    func startMonitoring() {
        // Restore any persisted shields and filters first (survives app kill)
        restoreShieldsIfNeeded()
        restoreWebFilterIfNeeded()
        
        if let data = sharedDefaults?.data(forKey: "com.truenyx.naviq.selection"),
           let selection = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) {
            print("ScreenTimeManager: startMonitoring found existing selection. Restoring events...")
            registerSelectedApps(selection: selection)
        } else {
            let center = DeviceActivityCenter()
            let schedule = DeviceActivitySchedule(
                intervalStart: DateComponents(hour: 0, minute: 0, second: 0),
                intervalEnd: DateComponents(hour: 23, minute: 59, second: 59),
                repeats: true
            )
            do {
                try center.startMonitoring(monitorName, during: schedule, events: [:])
                print("ScreenTimeManager: Started basic daily monitor (no apps selected yet)")
            } catch {
                print("ScreenTimeManager: Failed to start basic monitor: \(error)")
            }
        }
    }
    
    func getAccumulatedUsage() -> [[String: Any]] {
        guard let defaults = sharedDefaults else {
            print("ScreenTimeManager: sharedDefaults is nil!")
            return []
        }
        let records = defaults.array(forKey: usageKey) as? [[String: Any]] ?? []
        print("ScreenTimeManager: getAccumulatedUsage returning \(records.count) records")
        for record in records {
            let pkg = record["package"] as? String ?? "?"
            let sec = record["seconds"] as? Int ?? 0
            let name = record["appName"] as? String ?? "?"
            print("  → \(name) (\(pkg)): \(sec)s")
        }
        return records
    }
    
    func registerSelectedApps(selection: FamilyActivitySelection) {
        // Save selection for later use (shielding, restoring on restart)
        if let encoded = try? JSONEncoder().encode(selection) {
            sharedDefaults?.set(encoded, forKey: "com.truenyx.naviq.selection")
        }

        let center = DeviceActivityCenter()
        
        // Hard reset: stop old monitor, clear old data for clean slate
        center.stopMonitoring([monitorName])
        sharedDefaults?.removeObject(forKey: usageKey)
        sharedDefaults?.synchronize()
        
        let totalApps = selection.applicationTokens.count
        let totalCats = selection.categoryTokens.count
        let totalItems = totalApps + totalCats
        print("ScreenTimeManager: Registering \(totalApps) apps and \(totalCats) categories...")
        logToExtension("Registering \(totalApps) apps + \(totalCats) categories")
        
        // Calculate how many thresholds we can afford per item
        // Apple limits us to ~100 events total
        var thresholdsToUse = thresholds
        if totalItems > 0 {
            let maxThresholdsPerItem = max(1, maxEvents / totalItems)
            if maxThresholdsPerItem < thresholds.count {
                thresholdsToUse = Array(thresholds.prefix(maxThresholdsPerItem))
                print("ScreenTimeManager: ⚠️ Limiting to \(maxThresholdsPerItem) thresholds per item (event limit)")
            }
        }
        
        var events: [DeviceActivityEvent.Name: DeviceActivityEvent] = [:]
        
        // 1. Register individual apps
        for token in selection.applicationTokens {
            let baseName = "usage_app_\(token.hashValue)"
            for seconds in thresholdsToUse {
                let eventName = DeviceActivityEvent.Name("\(baseName)_\(seconds)")
                events[eventName] = DeviceActivityEvent(applications: [token], threshold: DateComponents(second: seconds))
            }
        }
        
        // 2. Register categories
        for token in selection.categoryTokens {
            let baseName = "usage_cat_\(token.hashValue)"
            for seconds in thresholdsToUse {
                let eventName = DeviceActivityEvent.Name("\(baseName)_\(seconds)")
                events[eventName] = DeviceActivityEvent(categories: [token], threshold: DateComponents(second: seconds))
            }
        }

        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0, second: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59, second: 59),
            repeats: true
        )

        print("ScreenTimeManager: Total events to register: \(events.count)")
        
        do {
            try center.startMonitoring(monitorName, during: schedule, events: events)
            print("ScreenTimeManager: ✅ Successfully registered \(events.count) events")
            logToExtension("✅ Registered \(events.count) events with \(thresholdsToUse.count) thresholds each")
        } catch {
            print("ScreenTimeManager: ❌ Failed to register events: \(error)")
            logToExtension("❌ Registration failed: \(error.localizedDescription)")
        }
    }

    private func logToExtension(_ message: String) {
        guard let defaults = sharedDefaults else { return }
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        let timestamp = formatter.string(from: Date())
        
        var logs = defaults.stringArray(forKey: "com.truenyx.naviq.extension_logs") ?? []
        logs.append("[\(timestamp)] Runner: \(message)")
        if logs.count > 100 { logs.removeFirst(logs.count - 100) }
        defaults.set(logs, forKey: "com.truenyx.naviq.extension_logs")
    }

    func getExtensionLogs() -> [String] {
        return sharedDefaults?.stringArray(forKey: "com.truenyx.naviq.extension_logs") ?? ["No logs found"]
    }

    private let lockedIdsKey = "com.truenyx.naviq.locked_ids"
    
    /// Returns the currently persisted lock list from App Group
    func getLockedIds() -> [String] {
        return sharedDefaults?.stringArray(forKey: lockedIdsKey) ?? []
    }
    
    func applyShields(ids: [String]) {
        // Persist lock list to App Group so it survives app kill/restart
        sharedDefaults?.set(ids, forKey: lockedIdsKey)
        sharedDefaults?.synchronize()
        
        guard let data = sharedDefaults?.data(forKey: "com.truenyx.naviq.selection"),
              let selection = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) else {
            print("ScreenTimeManager: No valid selection found for shielding")
            return
        }

        let store = ManagedSettingsStore()
        
        if ids.isEmpty {
            store.shield.applications = nil
            store.shield.applicationCategories = nil
            print("ScreenTimeManager: Cleared all shields")
            logToExtension("🔓 Cleared all shields")
            return
        }
        
        var tokensToShield = Set<ApplicationToken>()
        for token in selection.applicationTokens {
            let hashStr = "usage_app_\(token.hashValue)"
            if ids.contains(hashStr) {
                tokensToShield.insert(token)
            }
        }
        
        var categoriesToShield = Set<ActivityCategoryToken>()
        for token in selection.categoryTokens {
            let hashStr = "usage_cat_\(token.hashValue)"
            if ids.contains(hashStr) {
                categoriesToShield.insert(token)
            }
        }

        store.shield.applications = tokensToShield.isEmpty ? nil : tokensToShield
        store.shield.applicationCategories = categoriesToShield.isEmpty ? nil : .specific(categoriesToShield)
        print("ScreenTimeManager: Applied shields to \(tokensToShield.count) apps and \(categoriesToShield.count) categories")
        logToExtension("🔒 Shielded \(tokensToShield.count) apps + \(categoriesToShield.count) categories")
    }

    private let webFilterEnabledKey = "com.truenyx.naviq.web_filter_enabled"

    func applyWebContentFilter(enabled: Bool) {
        sharedDefaults?.set(enabled, forKey: webFilterEnabledKey)
        sharedDefaults?.synchronize()
        
        let store = ManagedSettingsStore()
        if #available(iOS 16.0, *) {
            if enabled {
                // Since ManagedSettings doesn't have a single "Adult Content" toggle,
                // we use .specific with a list of common adult domains as a starting point.
                // For a more robust solution, a larger blacklist or a whitelist approach is recommended.
                let blockedDomains: Set<WebDomain> = [
                    WebDomain(domain: "porn.com"),
                    WebDomain(domain: "xxx.com"),
                    WebDomain(domain: "pornhub.com"),
                    WebDomain(domain: "xvideos.com"),
                    WebDomain(domain: "redtube.com"),
                    WebDomain(domain: "xhamster.com")
                ]
                store.webContent.blockedByFilter = .specific(blockedDomains)
                print("ScreenTimeManager: Web content filter ENABLED for \(blockedDomains.count) domains")
                logToExtension("🚫 Enabled web filter for \(blockedDomains.count) domains")
            } else {
                store.webContent.blockedByFilter = nil
                print("ScreenTimeManager: Web content filter DISABLED")
                logToExtension("🔓 Disabled web filter")
            }
        }
    }

    func restoreWebFilterIfNeeded() {
        let enabled = sharedDefaults?.bool(forKey: webFilterEnabledKey) ?? false
        if enabled {
            print("ScreenTimeManager: Restoring web filter")
            applyWebContentFilter(enabled: true)
        }
    }
    
    /// Re-apply shields from persisted lock list (call on app launch)
    func restoreShieldsIfNeeded() {
        guard let ids = sharedDefaults?.stringArray(forKey: lockedIdsKey), !ids.isEmpty else {
            print("ScreenTimeManager: No persisted lock list to restore")
            return
        }
        print("ScreenTimeManager: Restoring shields for \(ids.count) items")
        applyShields(ids: ids)
    }
    
    /// Clear all shields and persisted lock state
    func clearShields() {
        sharedDefaults?.removeObject(forKey: lockedIdsKey)
        sharedDefaults?.synchronize()
        let store = ManagedSettingsStore()
        store.shield.applications = nil
        store.shield.applicationCategories = nil
        print("ScreenTimeManager: All shields cleared")
    }
}

// MARK: - FamilyActivityPicker SwiftUI Wrapper
@available(iOS 16.0, *)
struct FamilyActivityPickerView: View {
    @Binding var selection: FamilyActivitySelection
    @Binding var isPresented: Bool
    var onConfirm: (FamilyActivitySelection) -> Void
    var body: some View {
        NavigationView {
            FamilyActivityPicker(selection: $selection)
                .navigationTitle("Select Apps to Monitor")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) { Button("Cancel") { isPresented = false } }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") { onConfirm(selection); isPresented = false }.fontWeight(.semibold)
                    }
                }
        }
    }
}

@available(iOS 16.0, *)
class FamilyActivityPickerController: UIViewController {
    private var selection = FamilyActivitySelection()
    var onComplete: (([[String: Any]]) -> Void)?
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        let isPresented = Binding<Bool>(get: { true }, set: { [weak self] shown in if !shown { self?.dismiss(animated: true) } })
        let selectionBinding = Binding<FamilyActivitySelection>(get: { self.selection }, set: { self.selection = $0 })
        let hostingVC = UIHostingController(rootView: AnyView(FamilyActivityPickerView(selection: selectionBinding, isPresented: isPresented, onConfirm: { [weak self] finalSelection in self?.handleSelection(finalSelection) })))
        addChild(hostingVC)
        view.addSubview(hostingVC.view)
        hostingVC.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingVC.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingVC.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            hostingVC.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingVC.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
        hostingVC.didMove(toParent: self)
    }
    private func handleSelection(_ selection: FamilyActivitySelection) {
        print("FamilyActivityPicker: User confirmed selection. Total apps: \(selection.applicationTokens.count), Total categories: \(selection.categoryTokens.count)")
        
        var selectedItems: [[String: Any]] = []
        var appIndex = 1
        var catIndex = 1
        
        // Process individual apps — try to resolve real names
        for token in selection.applicationTokens {
            let hashID = "usage_app_\(token.hashValue)"
            let resolvedName = Self.resolveAppName(token: token) ?? "App \(appIndex)"
            print("FamilyActivityPicker: Selected app → \(hashID) → \"\(resolvedName)\"")
            selectedItems.append([
                "id": hashID,
                "type": "app",
                "displayName": resolvedName,
            ])
            appIndex += 1
        }
        
        // Process categories — try to resolve real names
        for token in selection.categoryTokens {
            let hashID = "usage_cat_\(token.hashValue)"
            let resolvedName = Self.resolveCategoryName(token: token) ?? "Category \(catIndex)"
            print("FamilyActivityPicker: Selected category → \(hashID) → \"\(resolvedName)\"")
            selectedItems.append([
                "id": hashID,
                "type": "category",
                "displayName": resolvedName,
            ])
            catIndex += 1
        }
        
        // Store mapping in App Group so extension can use resolved names
        let defaults = UserDefaults(suiteName: "group.com.truenyx.naviq")
        var tokenMap: [String: [String: Any]] = [:]
        for item in selectedItems {
            if let id = item["id"] as? String {
                tokenMap[id] = item
            }
        }
        if let data = try? JSONSerialization.data(withJSONObject: tokenMap) {
            defaults?.set(data, forKey: "com.truenyx.naviq.token_map")
        }
        
        ScreenTimeManager.shared.registerSelectedApps(selection: selection)
        onComplete?(selectedItems)
    }
    
    // MARK: - Token Name Resolution (Multi-Strategy)
    // Strategy 1: Render Label in a real window and extract text
    // Strategy 2: Try Codable encoding for readable data
    // Strategy 3: Use Mirror reflection on token internals
    
    private static func resolveAppName(token: ApplicationToken) -> String? {
        // Strategy 1: Window-based Label rendering
        if let name = extractNameViaWindow(AnyView(Label(token).labelStyle(.titleOnly))) {
            return name
        }
        // Strategy 2: Try Codable
        if let name = extractNameViaCodable(token) { return name }
        // Strategy 3: Mirror
        if let name = extractNameViaMirror(token) { return name }
        return nil
    }
    
    private static func resolveCategoryName(token: ActivityCategoryToken) -> String? {
        // Strategy 1: Window-based Label rendering
        if let name = extractNameViaWindow(AnyView(Label(token).labelStyle(.titleOnly))) {
            return name
        }
        // Strategy 2: Try Codable
        if let name = extractNameViaCodable(token) { return name }
        // Strategy 3: Mirror
        if let name = extractNameViaMirror(token) { return name }
        return nil
    }
    
    // MARK: Strategy 1 — Real window rendering
    private static func extractNameViaWindow(_ swiftUIView: AnyView) -> String? {
        let hostingVC = UIHostingController(rootView: swiftUIView)
        
        // Create a real window — SwiftUI won't actually render in a detached HostingController
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 50))
        window.rootViewController = hostingVC
        window.isHidden = false
        window.layoutIfNeeded()
        
        // Force Core Animation to flush
        CATransaction.flush()
        RunLoop.current.run(until: Date().addingTimeInterval(0.1))
        
        hostingVC.view.layoutIfNeeded()
        
        // Search for text in the rendered view hierarchy
        let result = findText(in: hostingVC.view)
        
        // Clean up
        window.isHidden = true
        window.rootViewController = nil
        
        return result
    }
    
    private static func findText(in view: UIView) -> String? {
        // Check accessibility elements
        if let elements = view.accessibilityElements {
            for element in elements {
                if let accElement = element as? NSObject,
                   let label = accElement.accessibilityLabel,
                   !label.isEmpty {
                    return label
                }
            }
        }
        
        // Check view's own accessibility label
        if let label = view.accessibilityLabel, !label.isEmpty,
           label != "Label" { // Filter out SwiftUI generic "Label"
            return label
        }
        
        // Check if it's a UILabel
        if let uiLabel = view as? UILabel, let text = uiLabel.text, !text.isEmpty {
            return text
        }
        
        // Recurse into subviews
        for subview in view.subviews {
            if let text = findText(in: subview) {
                return text
            }
        }
        return nil
    }
    
    // MARK: Strategy 2 — Codable encoding
    private static func extractNameViaCodable<T: Encodable>(_ token: T) -> String? {
        guard let data = try? JSONEncoder().encode(token),
              let str = String(data: data, encoding: .utf8) else { return nil }
        
        // Look for readable name patterns in the encoded JSON
        // Tokens may encode with a name or identifier field
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            // Try common keys
            for key in ["name", "displayName", "localizedName", "identifier", "rawValue"] {
                if let name = json[key] as? String, !name.isEmpty {
                    return name
                }
            }
        }
        
        // Check if the encoded string itself is a readable name (not just numbers/hashes)
        let cleaned = str.trimmingCharacters(in: CharacterSet(charactersIn: "\"{}[]"))
        if cleaned.count > 2 && cleaned.count < 50 &&
           cleaned.rangeOfCharacter(from: .letters) != nil &&
           !cleaned.contains("\\") {
            // Might be a simple string value
            print("FamilyActivityPicker: Codable output: \(str)")
        }
        
        return nil
    }
    
    // MARK: Strategy 3 — Mirror reflection
    private static func extractNameViaMirror(_ token: Any) -> String? {
        let mirror = Mirror(reflecting: token)
        for child in mirror.children {
            if let strValue = child.value as? String, !strValue.isEmpty {
                print("FamilyActivityPicker: Mirror found '\(child.label ?? "?")' = '\(strValue)'")
                return strValue
            }
            // Check nested mirrors
            let innerMirror = Mirror(reflecting: child.value)
            for innerChild in innerMirror.children {
                if let strValue = innerChild.value as? String, !strValue.isEmpty {
                    print("FamilyActivityPicker: Inner mirror found '\(innerChild.label ?? "?")' = '\(strValue)'")
                    return strValue
                }
            }
        }
        return nil
    }
}

// MARK: - UNUserNotificationCenterDelegate
@available(iOS 10, *)
extension AppDelegate {
  // Receive displayed notifications for iOS 10 devices (foreground)
  override func userNotificationCenter(_ center: UNUserNotificationCenter,
                              willPresent notification: UNNotification,
                              withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
    let userInfo = notification.request.content.userInfo
    
    if let messageID = userInfo["gcm.message_id"] {
      print("Message ID: \(messageID)")
    }
    
    // Handle lock/unlock in foreground
    if #available(iOS 16.0, *) {
      handleLockPayloadIfNeeded(userInfo)
    }
    
    print(userInfo)
    completionHandler([[.banner, .badge, .sound]])
  }
  
  // Handle notification tap
  override func userNotificationCenter(_ center: UNUserNotificationCenter,
                              didReceive response: UNNotificationResponse,
                              withCompletionHandler completionHandler: @escaping () -> Void) {
    let userInfo = response.notification.request.content.userInfo
    
    if let messageID = userInfo["gcm.message_id"] {
      print("Message ID: \(messageID)")
    }
    
    // Handle lock/unlock on tap
    if #available(iOS 16.0, *) {
      handleLockPayloadIfNeeded(userInfo)
    }
    
    print(userInfo)
    completionHandler()
  }
  
  // Shared helper — handles both old and new payload formats
  @available(iOS 16.0, *)
  private func handleLockPayloadIfNeeded(_ userInfo: [AnyHashable: Any]) {
    let type = userInfo["type"] as? String ?? (userInfo["gcm.notification.type"] as? String)
    let action = userInfo["action"] as? String
    
    let tokens = parseTokensFromPayload(userInfo)
    guard !tokens.isEmpty else { return }
    
    if action == "lock_apps" {
      print("AppDelegate notification: lock_apps — \(tokens.count) tokens")
      let existing = ScreenTimeManager.shared.getLockedIds()
      let merged = Array(Set(existing + tokens))
      ScreenTimeManager.shared.applyShields(ids: merged)
    } else if action == "unlock_apps" {
      print("AppDelegate notification: unlock_apps — \(tokens.count) tokens")
      let existing = ScreenTimeManager.shared.getLockedIds()
      let filtered = existing.filter { !tokens.contains($0) }
      ScreenTimeManager.shared.applyShields(ids: filtered)
    } else if type == "SYNC_LOCKED_APPS" {
      print("AppDelegate notification: SYNC_LOCKED_APPS — \(tokens.count) tokens")
      ScreenTimeManager.shared.applyShields(ids: tokens)
    }
  }
}

// MARK: - MessagingDelegate
extension AppDelegate: MessagingDelegate {
  func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
    print("Firebase registration token: \(String(describing: fcmToken))")
    
    let dataDict: [String: String] = ["token": fcmToken ?? ""]
    NotificationCenter.default.post(
      name: Notification.Name("FCMToken"),
      object: nil,
      userInfo: dataDict
    )
  }
}
