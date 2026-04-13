//
//  DeviceActivityMonitorExtension.swift
//  DeviceActivityMonitorExtension
//
//  Created by Fasna mohammed on 08/04/26.
//

import DeviceActivity
import Foundation
import ManagedSettings

// MARK: - DeviceActivityMonitor Extension
// iOS calls the methods in this extension when:
//   - A monitored schedule starts/ends (midnight reset)
//   - An app usage threshold event is crossed
//
// Data is written into App Group UserDefaults so the main Runner app
// can read it via ScreenTimeManager.getAccumulatedUsage().

// NOTE: This class name MUST match NSExtensionPrincipalClass in Info.plist
class DeviceActivityMonitorExtension: DeviceActivityMonitor {
    
    // MARK: - App Group Constants (must match Runner.entitlements + ScreenTimeManager)
    private let appGroupID = "group.com.truenyx.naviq"
    private let usageKey = "com.truenyx.naviq.screentime_data"
    
    private var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupID)
    }
    
    // MARK: - Interval Start (midnight) — reset daily usage
    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
        logToShared("intervalDidStart — clearing daily usage data")
        sharedDefaults?.removeObject(forKey: usageKey)
        sharedDefaults?.synchronize()
    }
    
    // MARK: - Interval End
    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        logToShared("intervalDidEnd")
    }
    
    // MARK: - Event Threshold Reached
    // iOS calls this each time an app crosses one of our pre-registered thresholds.
    // Event name format: "usage_app_HASH_SECONDS" or "usage_cat_HASH_SECONDS"
    // NOTE: HASH can be negative (e.g., -8475273408828014063)
    // so we parse from the END of the string, not the beginning.
    override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        super.eventDidReachThreshold(event, activity: activity)
        
        let eventName = event.rawValue
        logToShared("🔔 Threshold: \(eventName)")
        
        guard eventName.hasPrefix("usage_") else { return }
        
        // Parse from the END: the LAST "_" segment is always the seconds value
        // Everything before it is the baseID (which may contain negative numbers with dashes)
        guard let lastUnderscoreIndex = eventName.lastIndex(of: "_") else { return }
        
        let secondsStr = String(eventName[eventName.index(after: lastUnderscoreIndex)...])
        let baseID = String(eventName[..<lastUnderscoreIndex])
        
        guard let seconds = Int(secondsStr), seconds > 0 else {
            logToShared("⚠️ Could not parse seconds from: \(eventName)")
            return
        }
        
        // Determine display name — look up resolved name from token map first
        let displayName = resolveDisplayName(for: baseID)
        
        updateUsage(bundleID: baseID, appName: displayName, seconds: seconds)
    }
    
    /// Look up the display name from the token map stored during FamilyActivityPicker selection.
    /// Falls back to generic naming if no mapping found.
    private func resolveDisplayName(for baseID: String) -> String {
        if let mapData = sharedDefaults?.data(forKey: "com.truenyx.naviq.token_map"),
           let tokenMap = try? JSONSerialization.jsonObject(with: mapData) as? [String: [String: Any]],
           let entry = tokenMap[baseID],
           let name = entry["displayName"] as? String, !name.isEmpty {
            return name
        }
        // Fallback: generic name from the hash
        let isApp = baseID.hasPrefix("usage_app_")
        let typeName = isApp ? "App" : "Category"
        let hashPart = isApp
            ? String(baseID.dropFirst("usage_app_".count))
            : String(baseID.dropFirst("usage_cat_".count))
        return "\(typeName) (\(hashPart.suffix(6)))"
    }
    
    // MARK: - Storage Helper
    // Sets usage to the MAXIMUM value reached (thresholds only go up)
    private func updateUsage(bundleID: String, appName: String, seconds: Int) {
        guard let defaults = sharedDefaults else {
            logToShared("❌ sharedDefaults is nil!")
            return
        }
        
        var records = defaults.array(forKey: usageKey) as? [[String: Any]] ?? []
        
        if let index = records.firstIndex(where: { ($0["package"] as? String) == bundleID }) {
            let currentSeconds = records[index]["seconds"] as? Int ?? 0
            let newSeconds = max(currentSeconds, seconds)
            records[index]["seconds"] = newSeconds
            logToShared("📊 Updated \(bundleID) → \(newSeconds)s (was \(currentSeconds)s)")
        } else {
            records.append([
                "package": bundleID,
                "appName": appName,
                "seconds": seconds,
                "isSystemApp": false
            ])
            logToShared("📊 New record \(bundleID) → \(seconds)s")
        }
        
        defaults.set(records, forKey: usageKey)
        defaults.synchronize()
    }
    
    // MARK: - Diagnostic Logger
    private func logToShared(_ message: String) {
        guard let defaults = sharedDefaults else { return }
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        let timestamp = formatter.string(from: Date())
        
        var logs = defaults.stringArray(forKey: "com.truenyx.naviq.extension_logs") ?? []
        logs.append("[\(timestamp)] \(message)")
        // Keep last 100 logs for better debugging
        if logs.count > 100 { logs.removeFirst(logs.count - 100) }
        defaults.set(logs, forKey: "com.truenyx.naviq.extension_logs")
    }
    
    // MARK: - Optional Warning Callbacks
    override func intervalWillStartWarning(for activity: DeviceActivityName) {
        super.intervalWillStartWarning(for: activity)
    }
    
    override func intervalWillEndWarning(for activity: DeviceActivityName) {
        super.intervalWillEndWarning(for: activity)
    }
    
    override func eventWillReachThresholdWarning(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        super.eventWillReachThresholdWarning(event, activity: activity)
    }
}
