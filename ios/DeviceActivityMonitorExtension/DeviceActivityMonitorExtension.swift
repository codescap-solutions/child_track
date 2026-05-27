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
    private let usageKey   = "com.truenyx.naviq.screentime_data"

    // App Group credential keys (used for midnight best-effort upload)
    private let kAuthToken  = "com.truenyx.naviq.auth_token"
    private let kApiBaseUrl = "com.truenyx.naviq.api_base_url"
    private let kChildId    = "com.truenyx.naviq.child_id"
    private let kDayStartTs = "com.truenyx.naviq.day_start_ts"

    private var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupID)
    }

    /// Background URLSession — allows iOS to complete the upload even after
    /// the extension process is suspended at midnight.
    /// Identifier is unique to this target: "ext.sync" (AppDelegate uses "appdel.sync").
    private lazy var backgroundSession: URLSession = {
        let config = URLSessionConfiguration.background(
            withIdentifier: "com.truenyx.naviq.ext.sync"
        )
        config.isDiscretionary          = false   // upload immediately
        config.sessionSendsLaunchEvents = false   // extension doesn't need launch events
        config.timeoutIntervalForRequest  = 20
        config.timeoutIntervalForResource = 25
        return URLSession(configuration: config, delegate: nil, delegateQueue: nil)
    }()

    // MARK: - Interval Start (midnight) — reset daily usage

    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)

        // Record the day-start timestamp BEFORE clearing data
        // Parent app uses this to show "data fresh since X"
        let ts = Date().timeIntervalSince1970
        sharedDefaults?.set(ts, forKey: kDayStartTs)

        logToShared("intervalDidStart — recording day_start_ts=\(ts), clearing daily usage data")
        sharedDefaults?.removeObject(forKey: usageKey)
        // Optimization 5: no synchronize() here — UserDefaults syncs automatically
    }

    // MARK: - Interval End — best-effort midnight upload

    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        logToShared("intervalDidEnd — attempting best-effort final upload")
        uploadFinalUsageIfPossible()
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
        guard let lastUnderscoreIndex = eventName.lastIndex(of: "_") else { return }

        let secondsStr = String(eventName[eventName.index(after: lastUnderscoreIndex)...])
        let baseID     = String(eventName[..<lastUnderscoreIndex])

        guard let seconds = Int(secondsStr), seconds > 0 else {
            logToShared("⚠️ Could not parse seconds from: \(eventName)")
            return
        }

        let displayName = resolveDisplayName(for: baseID)
        updateUsage(bundleID: baseID, appName: displayName, seconds: seconds)
    }

    // MARK: - Display Name Resolution

    private func resolveDisplayName(for baseID: String) -> String {
        if let mapData  = sharedDefaults?.data(forKey: "com.truenyx.naviq.token_map"),
           let tokenMap = try? JSONSerialization.jsonObject(with: mapData) as? [String: [String: Any]],
           let entry    = tokenMap[baseID],
           let name     = entry["displayName"] as? String, !name.isEmpty {
            return name
        }
        let isApp    = baseID.hasPrefix("usage_app_")
        let typeName = isApp ? "App" : "Category"
        let hashPart = isApp
            ? String(baseID.dropFirst("usage_app_".count))
            : String(baseID.dropFirst("usage_cat_".count))
        return "\(typeName) (\(hashPart.suffix(6)))"
    }

    // MARK: - Storage Helper
    // Sets usage to the MAXIMUM value reached (thresholds only go up).
    // Also records the timestamp of the last threshold crossing.
    private func updateUsage(bundleID: String, appName: String, seconds: Int) {
        guard let defaults = sharedDefaults else {
            logToShared("❌ sharedDefaults is nil!")
            return
        }

        var records = defaults.array(forKey: usageKey) as? [[String: Any]] ?? []
        let now     = Date().timeIntervalSince1970

        if let index = records.firstIndex(where: { ($0["package"] as? String) == bundleID }) {
            let currentSeconds = records[index]["seconds"] as? Int ?? 0
            let newSeconds     = max(currentSeconds, seconds)
            records[index]["seconds"]         = newSeconds
            records[index]["lastThresholdTs"] = now
            logToShared("📊 Updated \(bundleID) → \(newSeconds)s (was \(currentSeconds)s)")
        } else {
            records.append([
                "package":         bundleID,
                "appName":         appName,
                "seconds":         seconds,
                "isSystemApp":     false,
                "lastThresholdTs": now
            ])
            logToShared("📊 New record \(bundleID) → \(seconds)s")
        }

        defaults.set(records, forKey: usageKey)
        // Optimization 5: ONE synchronize() here — threshold data must not be lost
        defaults.synchronize()
    }

    // MARK: - Midnight Best-Effort Upload (Optimization 3: backgroundSession)
    //
    // Using a lazy backgroundSession with identifier "com.truenyx.naviq.ext.sync"
    // allows iOS to complete the upload even AFTER this extension process is suspended.
    // This is best-effort only: no retry, no error alerting.

    private func uploadFinalUsageIfPossible() {
        guard
            let defaults  = sharedDefaults,
            let authToken = defaults.string(forKey: kAuthToken), !authToken.isEmpty,
            let childId   = defaults.string(forKey: kChildId),   !childId.isEmpty
        else {
            logToShared("⚠️ Missing credentials — skipping midnight upload")
            return
        }

        let records = defaults.array(forKey: usageKey) as? [[String: Any]] ?? []
        guard !records.isEmpty else {
            logToShared("ℹ️ No usage records — skipping midnight upload")
            return
        }

        let apiBase = defaults.string(forKey: kApiBaseUrl) ?? "https://naviq-server.codescap.com/api/v1/"

        // Build midnight UTC date string
        var utcCal = Calendar(identifier: .gregorian)
        utcCal.timeZone = TimeZone(identifier: "UTC")!
        let now         = Date()
        var comps       = utcCal.dateComponents([.year, .month, .day], from: now)
        comps.hour = 0; comps.minute = 0; comps.second = 0
        let midnight    = utcCal.date(from: comps) ?? now
        let dateStr     = ISO8601DateFormatter().string(from: midnight)

        // Field names match Dart ScreenTimeSyncService.uploadScreenTimeData exactly
        let appsData: [[String: Any]] = records.map { rec in
            [
                "packageName": rec["package"]  as? String ?? "",
                "appName":     rec["appName"]   as? String ?? "",
                "usageTime":   rec["seconds"]   as? Int    ?? 0,
                "isSystemApp": false
            ]
        }

        let payload: [String: Any] = [
            "userId":   childId,
            "date":     dateStr,
            "platform": "ios",
            "apps":     appsData
        ]

        guard let url  = URL(string: "\(apiBase)app-usage"),
              let body = try? JSONSerialization.data(withJSONObject: payload) else {
            logToShared("❌ Failed to build midnight upload request")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody   = body
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        // Optimization 3: use backgroundSession, not URLSession.shared
        // uploadTask survives extension suspension; background sessions handle completion
        // via the OS even after this process is killed.
        let task = backgroundSession.uploadTask(with: request, from: body)
        task.resume()

        logToShared("🌙 Midnight upload dispatched via backgroundSession (\(appsData.count) apps)")
    }

    // MARK: - Diagnostic Logger

    private func logToShared(_ message: String) {
        guard let defaults = sharedDefaults else { return }
        let ts = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)

        var logs = defaults.stringArray(forKey: "com.truenyx.naviq.extension_logs") ?? []
        logs.append("[\(ts)] \(message)")
        if logs.count > 100 { logs.removeFirst(logs.count - 100) }
        defaults.set(logs, forKey: "com.truenyx.naviq.extension_logs")
        // No synchronize() — logs are diagnostic only, auto-sync is sufficient
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
